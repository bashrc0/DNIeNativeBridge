#!/bin/bash
# Rebuild the pinned dependency sources for the published Intel target.
# Requires the Apple compiler tools plus Autoconf, Automake, GNU Libtool,
# pkg-config and gengetopt. It does not install system-wide software.
set -euo pipefail
DNIE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DNIE_DEPS="$DNIE_ROOT/ThirdParty/BuildInputs"
DNIE_WORK="$DNIE_ROOT/build/dependencies"
DNIE_PREFIX="$DNIE_WORK/prefix"
DNIE_JOBS="${DNIE_BUILD_JOBS:-4}"
# Autotools/pkg-config compiler flags cannot reliably quote spaces in prefixes.
case "$DNIE_ROOT" in *[[:space:]]*) echo 'Use a repository path without spaces for dependency reconstruction.' >&2; exit 1;; esac
for DNIE_TOOL in autoreconf automake pkg-config gengetopt make perl xcrun tar; do
    command -v "$DNIE_TOOL" >/dev/null || { echo "Missing prerequisite: $DNIE_TOOL" >&2; exit 1; }
done
if command -v glibtoolize >/dev/null; then
    export LIBTOOLIZE=glibtoolize
elif command -v libtoolize >/dev/null; then
    export LIBTOOLIZE=libtoolize
else
    echo 'Missing GNU Libtool (glibtoolize or libtoolize).' >&2; exit 1
fi
if [[ -e "$DNIE_WORK" ]]; then
    echo 'build/dependencies already exists. Preserve or remove it before starting a fresh rebuild.' >&2; exit 1
fi
mkdir -p "$DNIE_WORK/openssl" "$DNIE_WORK/openpace" "$DNIE_PREFIX"
tar -xzf "$DNIE_ROOT/ThirdParty/Sources/OpenSSL-3.5.tar.gz" -C "$DNIE_WORK/openssl"
tar -xzf "$DNIE_ROOT/ThirdParty/Sources/OpenPACE-1.1.4.tar.gz" -C "$DNIE_WORK/openpace"
cp -R "$DNIE_DEPS/OpenSC" "$DNIE_WORK/opensc"
export MACOSX_DEPLOYMENT_TARGET=15.5
export CC="$(xcrun --find clang)"
export SDKROOT="$(xcrun --show-sdk-path)"
export CFLAGS='-arch x86_64 -mmacosx-version-min=15.5 -O2'
export OBJCFLAGS="$CFLAGS"
export LDFLAGS='-arch x86_64 -mmacosx-version-min=15.5'
(
    cd "$DNIE_WORK/openssl"
    ./Configure darwin64-x86_64 no-shared no-apps no-tests no-dso no-engine \
        "--prefix=$DNIE_PREFIX/openssl" enable-ec_nistp_64_gcc_128
    make -j "$DNIE_JOBS"
    make install_sw
)
export CRYPTO_CFLAGS="-I$DNIE_PREFIX/openssl/include"
export CRYPTO_LIBS="-L$DNIE_PREFIX/openssl/lib -lcrypto"
export OPENSSL_CFLAGS="$CRYPTO_CFLAGS"
export OPENSSL_LIBS="$CRYPTO_LIBS"
export PKG_CONFIG_PATH="$DNIE_PREFIX/openssl/lib/pkgconfig:$DNIE_PREFIX/openpace/lib/pkgconfig"
(
    cd "$DNIE_WORK/openpace"
    autoreconf -vis
    ./configure --disable-shared "--prefix=$DNIE_PREFIX/openpace" HELP2MAN=/usr/bin/true
    touch src/cvc-create.1 src/cvc-print.1
    make -j "$DNIE_JOBS"
    make install
)
export OPENPACE_CFLAGS="-I$DNIE_PREFIX/openpace/include $OPENSSL_CFLAGS"
export OPENPACE_LIBS="-L$DNIE_PREFIX/openpace/lib -leac $OPENSSL_LIBS"
(
    cd "$DNIE_WORK/opensc"
    autoreconf -vis
    ./configure --disable-shared --prefix=/ --sysconfdir=/etc/opensc \
        --disable-pcsc --enable-cryptotokenkit
    make -j "$DNIE_JOBS"
)
# Publish the rebuilt inputs only after every dependency has compiled.
cp "$DNIE_PREFIX/openssl/lib/libcrypto.a" "$DNIE_DEPS/lib/libcrypto.a"
cp "$DNIE_PREFIX/openpace/lib/libeac.a" "$DNIE_DEPS/lib/libeac.a"
cp "$DNIE_WORK/opensc/src/libopensc/.libs/libopensc.a" "$DNIE_DEPS/lib/libopensc.a"
cp -R "$DNIE_PREFIX/openssl/include/." "$DNIE_DEPS/include/openssl/"
cp -R "$DNIE_PREFIX/openpace/include/." "$DNIE_DEPS/include/openpace/"
cp "$DNIE_WORK/opensc/config.h" "$DNIE_DEPS/OpenSC/config.h"
echo 'Dependencies rebuilt for Intel. Rebuild and sign the app, then validate with a card.'
echo 'Regenerate ThirdParty/SHA256SUMS before committing changed dependency inputs.'
