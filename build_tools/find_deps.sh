#!/usr/bin/env bash

if [ -z ${OTOOL+x} ]; then
if which otool&>/dev/null; then
    OTOOL=$(which otool)
elif which aarch64-apple-darwin-otool&>/dev/null; then
    OTOOL=$(which aarch64-apple-darwin-otool)
elif which x86_64-apple-darwin-otool&>/dev/null; then
    OTOOL=$(which x86_64-apple-darwin-otool)
else
    echo "Install otool"
    exit 1
fi
fi

if $(which grep) --version | grep -q GNU&>/dev/null; then
    GREP=grep
elif $(which ggrep) --version | grep -q GNU&>/dev/null; then
    GREP=$(which ggrep)
else
    echo "Install GNU grep"
    exit 1
fi

if [ -z ${1+x} ]; then
    echo "Usage: $0 path/to/libs/or/bins"
    exit 1
fi

find ${1} -type f -perm -111 -exec ${OTOOL} -L {} \; | \
    ${GREP} -o -P '(?<=lib\/)(.*).*dylib(?!:)' | \
    sort -u
