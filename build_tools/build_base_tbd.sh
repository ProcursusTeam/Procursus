#!/usr/bin/env bash

shopt -s globstar

if [ "$#" -ne 1 ]; then
	echo "Specify path"
	exit 1
fi

if [[ $(uname) = "Darwin" ]]; then
	TAPI="$(xcrun tapi)"
elif command -v tapi > /dev/null; then
	TAPI="$(command -v tapi)"
else
	echo "Please install tapi"
	exit 1
fi

echo -e "Note: this is unsupported, you will probably encounter errors while building packages\nstop now while you have the chance"
sleep 5

if which gsed >/dev/null; then
	SED=gsed
else
	SED=sed
fi

unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET APPLETVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET

${TAPI} stubify --filetype=tbd-v2 $1

for tbd in ${1}/**/*.tbd; do
	if [ -e $(rev <<< "$tbd" | cut -d'.' -f2- | rev).dylib -o -L $(rev <<< "$tbd" | cut -d'.' -f2- | rev).dylib ]; then
		rm -f $(rev <<< "$tbd" | cut -d'.' -f2- | rev).dylib
	fi
done
