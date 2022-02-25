#!/usr/bin/env bash

if [ -z ${OTOOL+x} ]; then
if command -v otool&>/dev/null; then
	OTOOL=$(command -v otool)
elif command -v aarch64-apple-darwin-otool&>/dev/null; then
	OTOOL=$(command -v aarch64-apple-darwin-otool)
elif command -v x86_64-apple-darwin-otool&>/dev/null; then
	OTOOL=$(command -v x86_64-apple-darwin-otool)
else
	echo "Install otool"
	exit 1
fi
fi

if $(command -v grep) --help 2>&1 | grep -q -- -P&>/dev/null; then
	GREP=grep
elif $(command -v ggrep) --help 2>&1 | grep -q -- -P&>/dev/null; then
	GREP=$(command -v ggrep)
elif /usr/local/bin/grep --help 2>&1 | grep -q -- -P&>/dev/null; then
	GREP=/usr/local/bin/grep
else
	echo "Install GNU grep"
	exit 1
fi

if [ -z ${1+x} ]; then
	echo "Usage: $0 path/to/libs/or/bins"
	exit 1
fi

find ${1} -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; \
	-exec ${OTOOL} -L {} \; | \
	${GREP} -o -P '((?<=lib\/)|(?<=@rpath\/))(.*).*dylib(?!:)' | \
	sort -u
