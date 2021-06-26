#!/bin/sh
if command -v gmake; then
	MAKE=gmake
else
	MAKE=make
fi
${MAKE} ${1}-setup
${MAKE} MEMO_TARGET=darwin-arm64 MEMO_CFVER=1700 rebuild-${1}-package &
${MAKE} MEMO_TARGET=darwin-amd64 MEMO_CFVER=1700 rebuild-${1}-package &
wait
