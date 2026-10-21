#!/bin/sh
# SMath Studio to binarka x86_64 (AppImage z wbudowanym Mono). Na aarch64
# (pandora / Apple Silicon) nie ma builda arm, więc puszczamy go przez
# qemu-user (binfmt_misc) dokładnie tak, jak mostek Antigravity w t3code:
#   - QEMU_LD_PREFIX -> sysroot z glibc x86_64 (loader ld-linux-x86-64),
#   - LD_LIBRARY_PATH -> x86_64 biblioteki GUI/mono, których AppImage nie wozi.
# AppRun ustawia już PATH/LD_LIBRARY_PATH/MONO_* względem własnego HERE.
export QEMU_LD_PREFIX="@SYSROOT@"
export LD_LIBRARY_PATH="@X64LIBS@:@SMATHDIR@/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "@SMATHDIR@/AppRun" "$@"
