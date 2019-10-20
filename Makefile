PLATFORM        ?= iphoneos
ARCH            ?= arm64
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
GNU_HOST_TRIPLE ?= aarch64-apple-darwin

iphoneos_VERSION_MIN := -miphoneos-version-min=11.0

DEB_ARCH       := iphoneos-arm64-thin
DEB_ORIGIN     := checkra1n
DEB_MAINTAINER := checkra1n

CFLAGS  := -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -I$(PWD)/build_base/include -I$(PWD)/dist/usr/lib
LDFLAGS := -L$(PWD)/build_base/lib -L$(PWD)/dist/usr/lib
DESTDIR := $(PWD)/dist

export CFLAGS LDFLAGS DESTDIR

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
PGP_VERIFY  = gpg --verify $(1).sig $(1) 2>&1 | grep -q 'Good signature'

EXTRACT_TAR = if [ ! -d $(3) ]; then \
		tar -xf $(1) && \
		mv $(2) $(3); \
	fi

ifeq ($(call HAS_COMMAND,shasum),1)
GET_SHA1   = shasum -a 1 $(1) | cut -c1-40
GET_SHA256 = shasum -a 256 $(1) | cut -c1-64
else
GET_SHA1   = sha1sum $(1) | cut -c1-40
GET_SHA256 = sha256sum $(1) | cut -c1-64
endif

ifeq ($(call HAS_COMMAND,gtar),1)
TAR := gtar
else ifeq ($(shell tar --version | grep -q GNU && echo 1),1)
TAR := tar
else
$(error Install GNU tar)
endif

ifeq ($(call HAS_COMMAND,gsed),1)
SED := gsed
else ifeq ($(shell sed --version | grep -q GNU && echo 1),1)
SED := sed
else
$(error Install GNU sed)
endif

ifneq ($(call HAS_COMMAND,gpg),1)
$(error Install GnuPG)
endif

ifeq ($(call HAS_COMMAND,ldid2),1)
LDID := ldid2
else ifeq ($(call HAS_COMMAND,ldid),1)
$(warning Using ldid. Abort now and install ldid2 if this ldid does not support SHA256)
LDID := ldid
else
$(error Install ldid2)
endif

ifneq ($(call HAS_COMMAND,cmake),1)
$(error Install cmake)
endif

ifneq ($(call HAS_COMMAND,cmake),1)
$(error Install cmake)
endif

ifeq ($(call HAS_COMMAND,fakeroot),1)
$(shell touch fakeroot_persist)
# FAKEROOT := fakeroot -i $(PWD)/fakeroot_persist -s $(PWD)/fakeroot_persist --
FAKEROOT :=
else
$(error Install fakeroot)
endif

ifeq ($(call HAS_COMMAND,dpkg-deb),1)
DPKG_DEB := dpkg-deb -z9
else ifeq ($(call HAS_COMMAND,dm.pl),1)
DPKG_DEB := dm.pl -Zlzma -z9
else
$(error Install dpkg-deb)
endif

ifeq ($(findstring --jobserver-auth=,$(MAKEFLAGS)),)
ifeq ($(call HAS_COMMAND,nproc),1)
GET_LOGICAL_CORES := nproc
else
GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
MAKEFLAGS += -j$(shell $(GET_LOGICAL_CORES)) -Otarget
endif

all: clean setup \
	coreutils sed grep findutils diffutils

setup:
	@# GNU bits
	wget -nc \
		https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/grep/grep-3.3.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/findutils/findutils-4.7.0.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/tar/tar-1.32.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-8.0-patches/readline80-001{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0-patches/bash50-00{1..9}{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0-patches/bash50-0{10..11}{,.sig}

	$(call PGP_VERIFY,coreutils-8.31.tar.xz)
	$(call PGP_VERIFY,sed-4.7.tar.xz)
	$(call PGP_VERIFY,grep-3.3.tar.xz)
	$(call PGP_VERIFY,findutils-4.7.0.tar.xz)
	$(call PGP_VERIFY,diffutils-3.7.tar.xz)
	$(call PGP_VERIFY,tar-1.32.tar.gz)
	$(call PGP_VERIFY,readline-8.0.tar.gz)
	$(call PGP_VERIFY,readline80-001)
	$(call PGP_VERIFY,bash-5.0.tar.gz)
	$(call PGP_VERIFY,bash50-001)
	$(call PGP_VERIFY,bash50-002)
	$(call PGP_VERIFY,bash50-003)
	$(call PGP_VERIFY,bash50-004)
	$(call PGP_VERIFY,bash50-005)
	$(call PGP_VERIFY,bash50-006)
	$(call PGP_VERIFY,bash50-007)
	$(call PGP_VERIFY,bash50-008)
	$(call PGP_VERIFY,bash50-009)
	$(call PGP_VERIFY,bash50-010)
	$(call PGP_VERIFY,bash50-011)

	$(call EXTRACT_TAR,coreutils-8.31.tar.xz,coreutils-8.31,coreutils)
	$(call EXTRACT_TAR,sed-4.7.tar.xz,sed-4.7,sed)
	$(call EXTRACT_TAR,grep-3.3.tar.xz,grep-3.3,grep)
	$(call EXTRACT_TAR,findutils-4.7.0.tar.xz,findutils-4.7.0,findutils)
	$(call EXTRACT_TAR,diffutils-3.7.tar.xz,diffutils-3.7,diffutils)
	$(call EXTRACT_TAR,tar-1.32.tar.gz,tar-1.32,tar)
	$(call EXTRACT_TAR,readline-8.0.tar.gz,readline-8.0,readline)
	$(call EXTRACT_TAR,bash-5.0.tar.gz,bash-5.0,bash)

	patch -p0 -d readline < readline80-001
	patch -p0 -d bash < bash50-001
	patch -p0 -d bash < bash50-002
	patch -p0 -d bash < bash50-003
	patch -p0 -d bash < bash50-004
	patch -p0 -d bash < bash50-005
	patch -p0 -d bash < bash50-006
	patch -p0 -d bash < bash50-007
	patch -p0 -d bash < bash50-008
	patch -p0 -d bash < bash50-009
	patch -p0 -d bash < bash50-010
	patch -p0 -d bash < bash50-011

	@# Note: iOS 10+ specific API
	cp $(SYSROOT)/usr/include/time.h build_base/include/
	$(SED) -Ei s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g build_base/include/time.h

export CHECKRA1N_MEMO := 1

include coreutils.mk
include sed.mk
include grep.mk
include findutils.mk
include diffutils.mk
include tar.mk
include readline.mk
include bash.mk

clean::
	rm -rf dist fakeroot_persist
	rm -rf build_base/include/time.h
	rm -rf coreutils sed grep findutils diffutils tar readline bash

.PHONY: setup clean
