#!/bin/bash
set -e

COMMIT="236a426c1205a3bfcf0dbb2e2faf2296f0a100e5"

TRIPLES=(
  "armv7-apple-darwin"
  "armv7k-apple-darwin"
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
)

git clone https://github.com/tpoechtrager/cctools-port.git /tmp/cctools
pushd /tmp/cctools/cctools
for TRIPLE in "${TRIPLES[@]}"; do
  ./configure \
    --prefix=/usr/local \
    --with-libtapi=/usr/local \
    --target=${TRIPLE}
  make -j$(nproc)
  make install
  make clean
done
popd

rm -rf /tmp/cctools
