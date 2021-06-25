#!/bin/sh
if command -v gmake; then
	MAKE=gmake
else
	MAKE=make
fi
${MAKE} MEMO_TARGET=iphoneos-arm64 ${1}-setup
${MAKE} MEMO_TARGET=iphoneos-arm64 MEMO_CFVER=1500 rebuild-${1}-package &
${MAKE} MEMO_TARGET=iphoneos-arm64 MEMO_CFVER=1600 rebuild-${1}-package &
${MAKE} MEMO_TARGET=iphoneos-arm64 MEMO_CFVER=1700 rebuild-${1}-package &
wait
