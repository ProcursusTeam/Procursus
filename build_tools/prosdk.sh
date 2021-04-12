#!/usr/bin/env bash

shopt -s extglob nullglob

if [ $# != 3 ] || [ $# != 4]; then
	echo -e "Usage: $0 [PATH TO DEBS] [IPHONEOS_SYSROOT] [MACOSX_SYSROOT]
       $0 [TARGET] [CFVER] [IPHONEOS_SYSROOT] [MACOSX_SYSROOT]
       (download the debs from apt.procurs.us)"
	exit
fi

if [ $# == 3 ]; then
	ROOT=$1
	OUT_SYSROOT=$2
	MACOSX_SYSROOT=$3
elif [ $# == 4 ]; then
	TARGET=$1
	CFVER=$2
	ROOT="apt.procurs.us/${CFVER}"
	OUT_SYSROOT=$3
	MACOSX_SYSROOT=$4
	
	echo "Downloading from apt.procurs.us (this will take a while)"
	wget -r -np -q --show-progress -R "index.html" --cut-dirs=3 https://apt.procurs.us/pool/main/${TARGET}/${CFVER}/
	rm $ROOT/index.html*
fi

echo "Removing old debs"
for deb1 in ${ROOT}/*.deb; do
	if [ ! -f $deb1 ]; then
		continue
	fi
	name1=$(dpkg-deb -f $deb1 Package)
	version1=$(dpkg-deb -f $deb1 Version)
	for deb2 in ${ROOT}/${name1}_*.deb; do
		name2=$(dpkg-deb -f "$deb2" Package)
		version2=$(dpkg-deb -f "$deb2" Version)
		if [ "$version1" == "$version2" ]; then
			continue
		fi
		if [ "$name1" == "$name2" ]; then
			if dpkg --compare-versions $version1 gt $version2; then
				rm "$deb2"
			else
				rm "$deb1"
				break
			fi
		fi
	done
done

echo "Removing unneeded debs"
unset deb
for deb in ${ROOT}/*.deb; do
	if dpkg-deb -f $deb Package | grep "swift" >/dev/null; then
		# swift packages are dumb and don't conflict with each other, but have headers which we don't need anyway
		rm "$deb"
		continue
	fi
	if ! dpkg-deb -c $deb | grep -E "/usr/include/.*\.h|/usr/lib/.*\.dylib" >/dev/null; then
		rm "$deb"
	fi
done

echo "Patching and copying headers"
mkdir -p $OUT_SYSROOT/{{,System}/Library/Frameworks,usr/{include/{bsm,objc,os,sys,IOKit,libkern,mach/machine},lib}}
wget -q -nc -P $OUT_SYSROOT/usr/include \
	https://opensource.apple.com/source/xnu/xnu-6153.61.1/libsyscall/wrappers/spawn/spawn.h
wget -q -nc -P $OUT_SYSROOT/usr/include/mach/machine \
	https://opensource.apple.com/source/xnu/xnu-6153.81.5/osfmk/mach/machine/thread_state.h
wget -q -nc -P $OUT_SYSROOT/usr/include/bsdm \
	https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/bsm/audit_kevents.h

cp -af $MACOSX_SYSROOT/usr/include/{arpa,net,xpc,netinet} $OUT_SYSROOT/usr/include
cp -af $MACOSX_SYSROOT/usr/include/objc/objc-runtime.h $OUT_SYSROOT/usr/include/objc
cp -af $MACOSX_SYSROOT/usr/include/libkern/OSTypes.h $OUT_SYSROOT/usr/include/libkern
cp -af $MACOSX_SYSROOT/usr/include/sys/{tty*,proc*,ptrace,kern*,random,vnode}.h $OUT_SYSROOT/usr/include/sys
cp -af $MACOSX_SYSROOT/System/Library/Frameworks/IOKit.framework/Headers/* $OUT_SYSROOT/usr/include/IOKit
cp -af $MACOSX_SYSROOT/usr/include/{ar,launch,libcharset,localcharset,libproc,tzfile}.h $OUT_SYSROOT/usr/include
cp -af $MACOSX_SYSROOT/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $OUT_SYSROOT/usr/include/mach
cp -af $MACOSX_SYSROOT/usr/include/mach/machine/*.defs $OUT_SYSROOT/usr/include/mach/machine
cp -af /home/cameron/Documents/Procursus/build_info/availability.h $OUT_SYSROOT/usr/include/os

sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/stdlib.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/time.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/unistd.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/mach/task.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/mach/mach_host.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/ucontext.h
sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g -i $OUT_SYSROOT/usr/include/signal.h
sed -E /'__API_UNAVAILABLE'/d -i $OUT_SYSROOT/usr/include/pthread.h

echo "Extracting debs into SDK"
for deb in ${ROOT}/*.deb; do
	dpkg-deb -x $deb $OUT_SYSROOT
done

echo "Converting to tbd stubs"
if [[ $(uname) = "Darwin" ]]; then
	TAPI="$(xcrun tapi)"
elif command -v tapi > /dev/null; then
	TAPI="$(command -v tapi)"
elif command -v tbd > /dev/null; then
	TBD="$(command -v tbd)"
else
	exit 0
fi

unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET APPLETVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET

fixext() {
	echo "$1" | rev | \
		cut -d. -f 2- | \
		rev | \
		sed 's/.*/&.tbd/'
}

shopt -s globstar

for dylib in ${OUT_SYSROOT}/usr/lib/**/*.dylib ${OUT_SYSROOT}/usr/local/lib/**/*.dylib; do
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
	rm -f "$dylib"
done

echo "Clean up"
find $OUT_SYSROOT -type f -executable -delete
rm -rf $OUT_SYSROOT/etc $OUT_SYSROOT/**/bin/* $OUT_SYSROOT/usr/share/!(sandbox)
find $OUT_SYSROOT -empty -type d -delete
