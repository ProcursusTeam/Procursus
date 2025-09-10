#!/bin/bash
set -e

COMMIT="236a426c1205a3bfcf0dbb2e2faf2296f0a100e5"

TRIPLES=(
  "armv6-apple-darwin"
  "armv7-apple-darwin"
  "armv7k-apple-darwin"
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
)

#Install libdispatch
git clone https://github.com/apple/swift-corelibs-libdispatch
cd swift-corelibs-libdispatch
mkdir bb && cd bb
CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j $(nproc)
make install
cd ../../
rm -rf swift-corelibs-libdispatch

git clone --depth=1 https://github.com/apple/llvm-project -b llvm.org/release/20.x /tmp/llvm-project
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
