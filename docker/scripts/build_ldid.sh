#!/bin/bash
set -e

# ldid
git clone git://git.saurik.com/ldid.git /tmp/ldid
pushd /tmp/ldid
git submodule update --init
g++ -O3 -g0 -c -std=c++11 -o ldid.o ldid.cpp
g++ -O3 -g0 -o ldid ldid.o -x c lookup2.c -lxml2 -lcrypto -lplist-2.0
mv -f ./ldid /usr/local/bin/ldid
chmod +x /usr/local/bin/ldid
popd

rm -rf /tmp/ldid
