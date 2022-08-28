#!/bin/bash
set -e

VERSION="1100.0.11"

git clone --branch ${VERSION} https://github.com/tpoechtrager/apple-libtapi.git /tmp/tapi

mkdir -p /tmp/tapi/build

pushd /tmp/tapi/build
INCLUDE_FIX="-I $PWD/../src/llvm/projects/clang/include "
INCLUDE_FIX+="-I $PWD/projects/clang/include "

cmake ../src/llvm \
  -DCMAKE_CXX_FLAGS="${INCLUDE_FIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DTAPI_FULL_VERSION="${VERSION}" \
  -DLLVM_ENABLE_PROJECTS="libtapi" \
  -DTAPI_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_TESTS=OFF

make -j$(nproc) clangBasic libtapi tapi
make -j$(nproc) install-libtapi install-tapi-headers install-tapi
popd
rm -rf /tmp/tapi
