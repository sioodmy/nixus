#! /bin/sh
# T3 Code Antigravity launcher for 16K-page ARM (pandora / Apple Silicon).
#
# Google ships agy_acp_server.par as a 4K-page x86_64 binary with a fatal
# startup check (`sysconf(_SC_PAGE_SIZE) == 4096`), while nixos-apple-silicon
# is 16K-only. So the ACP server cannot run natively here. This wrapper
# executes the official runtime through qemu-user (binfmt handles the
# arch transparently) with an x86_64 glibc sysroot.
#
# T3 spawns its provider binaries with a scrubbed environment
# (extendEnv: false), so everything the runtime needs is set here from
# absolute store paths -- no $HOME, no $PATH lookups.
#
# The sibling localharness_external must stay next to agy_acp_server.par:
# T3 resolves it relative to this executable (its "Binary path" setting).
export QEMU_LD_PREFIX="@OUT@/x86_64-sysroot"
: "${SSL_CERT_FILE:=@CACERT@}"
export SSL_CERT_FILE
export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"
export REQUESTS_CA_BUNDLE="$SSL_CERT_FILE"
export CURL_CA_BUNDLE="$SSL_CERT_FILE"
exec "@OUT@/bin/agy_acp_server.par" "$@"
