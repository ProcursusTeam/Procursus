#!/usr/bin/env bash

if [[ $(uname) = "Darwin" ]]; then
	TAPI="$(xcrun tapi)"
elif command -v tapi > /dev/null; then
	TAPI="$(command -v tapi)"
elif command -v tbd > /dev/null; then
	TBD="$(command -v tbd)"
else
	exit 0
fi

unset MACOSX_DEPLOYMENT_TARGET

fixext() {
	echo "$1" | rev | \
		cut -d. -f 2- | \
		rev | \
		sed 's/.*/&.tbd/'
}

for lib in $(find ${BUILD_BASE}/usr/lib -type f -name "*.dylib"); do
	if [ -z ${TAPI+x} ]; then
		tbd -p $lib -o $(fixext "$lib")
	else
		${TAPI} stubify "$lib"
	fi
	rm $lib
done

for symlink in $(find ${BUILD_BASE}/${MEMO_TARGET}/${MEMO_CFVER}/usr/lib -type l -name "*.dylib"); do
	ln -sf $(fixext $(readlink "$symlink")) $(fixext "$symlink")
	rm $symlink
done

for lib in $(find ${BUILD_BASE}/usr/local/lib -type f -name "*.dylib"); do
	if [ -z ${TAPI+x} ]; then
		tbd -p $lib -o $(fixext "$lib")
	else
		${TAPI} stubify "$lib"
	fi
	rm $lib
done

for symlink in $(find ${BUILD_BASE}/usr/local/lib -type l -name "*.dylib"); do
	ln -sf $(fixext $(readlink "$symlink")) $(fixext "$symlink")
	rm $symlink
done
