"""Repair a SEP host-state store that a power cut left short.

The driver refuses any file whose size is not the full 72-block store, and
does not reinitialise it: a short file that is not all zero may be the only
copy of the host state.  That is the right call for the driver, but it leaves
Touch ID dead until someone looks at the file.

The store is a superblock followed by copy-on-write slot blocks.  A short file
is normally a prefix of a valid store, cut off during a write (the superblock
is rewritten first and is therefore intact).  If the superblock validates and
every slot it names ends inside the file, zero-extending the file back to the
full size preserves all state.  Anything else is moved aside, untouched, so
the driver creates a fresh store.

This runs before aurora-sep.service loads apple_sep; it never touches a file
of the full size.
"""

import os
import shutil
import sys
import time

STORE = "/var/lib/aurora-sep-host-state.bin"
QUARANTINE = "/var/lib/aurora-sep-quarantine"

BLOCK_SIZE = 0x8000
BLOCK_COUNT = 72
STORE_SIZE = BLOCK_SIZE * BLOCK_COUNT
SLOT_COUNT = BLOCK_COUNT - 1
MAX_VALUE = BLOCK_SIZE

MAGIC = b"AURORA-SEP-STOR\x01"
VERSION = 1

SB_MAGIC = 0
SB_VERSION = 16
SB_SLOT_COUNT = 20
SB_BLOCK_SIZE = 24
SB_INTENT_KIND = 36
SB_INTENT_SLOT = 37
SB_INTENT_TYPE = 39
SB_RESERVED = 40
SB_SLOT_TABLE = 64
SLOT_ENTRY_SIZE = 24
SB_SLOT_TABLE_END = SB_SLOT_TABLE + SLOT_COUNT * SLOT_ENTRY_SIZE

INTENT_NONE = 0
INTENT_WRITE = 1


def log(message):
    print(f"aurora-sep-host-state-repair: {message}", flush=True)


def le32(buf, off):
    return int.from_bytes(buf[off:off + 4], "little")


def le64(buf, off):
    return int.from_bytes(buf[off:off + 8], "little")


def all_zero(path, size):
    with open(path, "rb") as f:
        left = size
        while left:
            chunk = f.read(min(left, 1 << 20))
            if not chunk:
                return False
            if any(chunk):
                return False
            left -= len(chunk)
    return True


def validate_superblock(sb):
    """Return (ok, detail, highest_end).

    Mirrors Store::decode in drivers/soc/apple/store.rs.  highest_end is the
    first byte past the last data block the superblock names.
    """
    if len(sb) < SB_SLOT_TABLE_END:
        return False, "superblock too short", 0
    if sb[SB_MAGIC:SB_MAGIC + 16] != MAGIC:
        return False, "bad magic", 0
    if le32(sb, SB_VERSION) != VERSION:
        return False, "unsupported version", 0
    if le32(sb, SB_SLOT_COUNT) != SLOT_COUNT:
        return False, "slot count mismatch", 0
    if le32(sb, SB_BLOCK_SIZE) != BLOCK_SIZE:
        return False, "block size mismatch", 0
    if any(sb[SB_RESERVED:SB_SLOT_TABLE]):
        return False, "reserved header bytes are set", 0
    if any(sb[SB_SLOT_TABLE_END:BLOCK_SIZE]):
        return False, "reserved superblock bytes are set", 0

    slots = []
    seen = set()
    highest_end = 0
    for i in range(SLOT_COUNT):
        off = SB_SLOT_TABLE + i * SLOT_ENTRY_SIZE
        entry = sb[off:off + SLOT_ENTRY_SIZE]
        if not any(entry):
            slots.append(None)
            continue
        if entry[0] != 1:
            return False, f"slot {i}: bad used flag", 0
        if not 0xF0 <= entry[1] <= 0xF5:
            return False, f"slot {i}: unknown kind", 0
        length = le32(entry, 18)
        if length > MAX_VALUE:
            return False, f"slot {i}: value too large", 0
        if any(entry[22:]):
            return False, f"slot {i}: reserved bytes are set", 0
        key = (entry[1], bytes(entry[2:18]))
        if key in seen:
            return False, f"slot {i}: duplicate key", 0
        seen.add(key)
        slots.append(length)
        highest_end = max(highest_end, (i + 1) * BLOCK_SIZE + length)

    intent_kind = sb[SB_INTENT_KIND]
    intent_slot = int.from_bytes(
        sb[SB_INTENT_SLOT:SB_INTENT_SLOT + 2], "little"
    )
    intent_type = sb[SB_INTENT_TYPE]
    if intent_kind == INTENT_NONE:
        if intent_slot != 0 or intent_type != 0:
            return False, "bad empty intent", 0
    elif intent_kind == INTENT_WRITE:
        if intent_slot >= SLOT_COUNT:
            return False, "intent names an out-of-range slot", 0
        if slots[intent_slot] is not None:
            return False, "intent names a used slot", 0
        if not 0xF0 <= intent_type <= 0xF5:
            return False, "intent has an unknown kind", 0
    else:
        return False, "unknown intent", 0

    used = sum(1 for length in slots if length is not None)
    detail = (
        f"generation {le64(sb, 28)}, {used} used slot(s), "
        f"data ends at {highest_end}"
    )
    return True, detail, highest_end


def backup(path, size):
    os.makedirs(QUARANTINE, mode=0o700, exist_ok=True)
    os.chmod(QUARANTINE, 0o700)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    base = os.path.join(QUARANTINE, f"host-state-{stamp}-{size}")
    dest = f"{base}.bin"
    suffix = 1
    while True:
        try:
            dst = open(dest, "xb")
        except FileExistsError:
            dest = f"{base}-{suffix}.bin"
            suffix += 1
            continue
        break
    with open(path, "rb") as src, dst:
        shutil.copyfileobj(src, dst)
        dst.flush()
        os.fsync(dst.fileno())
    os.chmod(dest, 0o600)
    return dest


def main():
    try:
        size = os.path.getsize(STORE)
    except FileNotFoundError:
        log("no host-state store yet; leaving it to the driver")
        return 0
    except OSError as e:
        log(f"cannot stat {STORE}: {e}")
        return 1

    if size == STORE_SIZE:
        return 0

    if size == 0 or (size < STORE_SIZE and all_zero(STORE, size)):
        log(f"{STORE} is {size} bytes and all zero; leaving it to the driver")
        return 0

    with open(STORE, "rb") as f:
        sb = f.read(BLOCK_SIZE)

    ok, detail, highest_end = validate_superblock(sb)
    header = sb[:64].hex()
    log(
        f"{STORE} is {size} bytes, expected {STORE_SIZE}; "
        f"superblock: {header}"
    )

    if not ok:
        try:
            dest = backup(STORE, size)
        except OSError as e:
            log(f"cannot back up the damaged store: {e}")
            return 1
        os.unlink(STORE)
        log(
            f"{detail}; moved the file to {dest}, "
            "the driver will create a fresh store"
        )
        return 0

    if highest_end > size:
        try:
            dest = backup(STORE, size)
        except OSError as e:
            log(f"cannot back up the damaged store: {e}")
            return 1
        os.unlink(STORE)
        log(
            f"{detail}: a used slot ends past the file; moved it to {dest}, "
            "the driver will create a fresh store"
        )
        return 0

    try:
        dest = backup(STORE, size)
    except OSError as e:
        log(f"cannot back up the short store: {e}")
        return 1

    fd = os.open(STORE, os.O_RDWR)
    try:
        os.ftruncate(fd, STORE_SIZE)
        os.fsync(fd)
    finally:
        os.close(fd)
    log(
        f"{detail}; backed up as {dest} and zero-extended {STORE} to "
        f"{STORE_SIZE} bytes"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
