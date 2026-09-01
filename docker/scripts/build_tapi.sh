#!/bin/bash
set -e

VERSION="1600.0.11.8"

git clone --branch ${VERSION} https://github.com/tpoechtrager/apple-libtapi.git /tmp/tapi

mkdir -p /tmp/tapi

pushd /tmp/tapi
INSTALLPREFIX="/usr/local" ./build.sh
./install.sh
popd
rm -rf /tmp/tapi
