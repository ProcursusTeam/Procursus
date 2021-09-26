#!/usr/bin/env bash

if [ ! -e ${BUILD_WORK}/${1}/.build_complete ]; then
	pkgnames=$(grep "call PACK" makefiles/${1}.mk | cut -d, -f2)
	temp=$(grep -m 1 "call PACK" makefiles/${1}.mk | cut -d, -f3)
	
	versionString=${temp::-1}
	
	version=$(MEMO_QUIET=1 ${MAKE} print-${versionString})
	
	for pkg in $pkgnames; do
		if grep -q "@DEB_ARCH@" build_info/${pkg}.control; then
			arch="${DEB_ARCH}"
		else
			arch="$(grep "Architecture:" build_info/${pkg}.control | cut -d" " -f2)"
		fi
		debs="${debs} $(printf "%s_%s_%s.deb\n" $pkg $version $arch)"
	done
	
	for pkg in $debs; do
		if grep -q "darwin" <<< $MEMO_TARGET; then
			if ! wget -q -P ${BUILD_DIST} https://apt.procurs.us/pool/main/"${MACOSX_SUITE_NAME}"/${pkg}; then
				echo "${pkg} is not available, building from source."
				${MAKE} ${1}
				exit 0;
			fi
		else
			if ! wget -q -P ${BUILD_DIST} https://apt.procurs.us/pool/main/"${MEMO_TARGET}"/"${MEMO_CFVER}"/${pkg}; then
				echo "${pkg} is not available, building from source."
				${MAKE} ${1}
				exit 0;
			fi
		fi
		dpkg -x ${BUILD_DIST}/${pkg} ${BUILD_BASE}
	done
	
	mkdir -p ${BUILD_WORK}/${1}
	touch ${BUILD_WORK}/${1}/.build_complete
else
	echo "${1} is already in build_base."
fi
