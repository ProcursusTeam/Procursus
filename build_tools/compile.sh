#!/bin/sh

set -e

for pkg in $@; do
	./build_tools/compile_macos.sh $pkg
	./build_tools/compile_iphoneos.sh $pkg
done
