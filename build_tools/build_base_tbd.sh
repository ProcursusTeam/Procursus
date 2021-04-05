#!/usr/bin/env bash

shopt -s globstar

echo -e "Note: this is unsupported, you will probably encounter errors while building packages\nstop now while you have the chance"
sleep 5

if [[ $(uname) = "Darwin" ]]; then
	TAPI="$(xcrun tapi)"
elif command -v tapi > /dev/null; then
	TAPI="$(command -v tapi)"
elif command -v tbd > /dev/null; then
	TBD="$(command -v tbd)"
else
	echo "Please install either tapi or tbd"
	exit 1
fi

unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET APPLETVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET

fixext() {
	echo "$1" | rev | \
		cut -d. -f 2- | \
		rev | \
		sed 's/.*/&.tbd/'
}

for dylib in ${BUILD_BASE}${MEMO_PREFIX}${MEMO_SUB_PREFIX}/lib/**/*.dylib ${BUILD_BASE}${MEMO_PREFIX}${MEMO_SUB_PREFIX}${MEMO_ALT_PREFIX}/lib/**/*.dylib; do
	if file -Nb "$dylib" | grep "shared library" >/dev/null; then
		if [ -L $lib ]; then
			ln -sf $(fixext $(readlink "$dylib")) $(fixext "$dylib")
		else
			if [ -z ${TAPI+x} ]; then
				tbd -p $lib -o $(fixext "$dylib") -v2
			else
				${TAPI} stubify "$dylib" --filetype=tbd-v2
			fi
		fi
	fi
	rm "$dylib"
done
