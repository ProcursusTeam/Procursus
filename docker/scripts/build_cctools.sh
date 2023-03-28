#!/bin/bash
set -e

COMMIT="236a426c1205a3bfcf0dbb2e2faf2296f0a100e5"

TRIPLES=(
  "armv7-apple-darwin"
  "armv7k-apple-darwin"
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
)

git clone --depth=1 https://github.com/apple/llvm-project -b llvm.org/release/16.x /tmp/llvm-project
pushd /tmp/llvm-project
cmake -S llvm -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" -DLLVM_TARGETS_TO_BUILD="ARM;X86;AArch64"
pushd build
make -j $(nproc) || exit 1
make install || exit 1
popd
popd
rm -rf /tmp/llvm-project


git clone https://github.com/tpoechtrager/cctools-port.git /tmp/cctools
pushd /tmp/cctools/cctools
for TRIPLE in "${TRIPLES[@]}"; do
  ./configure \
    --prefix=/usr/local \
    --with-libtapi=/usr/local \
    --target=${TRIPLE}
  make -j$(nproc) || exit 1
  make install || exit 1
  make clean || exit 1
done
popd

rm -rf /tmp/cctools
