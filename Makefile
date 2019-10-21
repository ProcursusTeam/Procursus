PLATFORM        ?= iphoneos
ARCH            ?= arm64
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
GNU_HOST_TRIPLE ?= aarch64-apple-darwin

iphoneos_VERSION_MIN := -miphoneos-version-min=11.0

DEB_ARCH       := iphoneos-arm64-thin
DEB_ORIGIN     := checkra1n
DEB_MAINTAINER := checkra1n

CFLAGS   := -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem $(PWD)/build_base/include -I$(PWD)/dist/usr/include
CXXFLAGS := -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem $(PWD)/build_base/include -I$(PWD)/dist/usr/include
LDFLAGS  := -L$(PWD)/build_base/lib -L$(PWD)/dist/usr/lib
DESTDIR  := $(PWD)/dist

export CFLAGS CXXFLAGS LDFLAGS DESTDIR

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
PGP_VERIFY  = gpg --verify $(1).$(if $(2),$(2),sig) $(1) 2>&1 | grep -q 'Good signature'

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

SOURCEDIR := $(PWD)/source

MAKEFLAGS += --no-print-directory

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
	wget -nc -P $(SOURCEDIR) \
		https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/grep/grep-3.3.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/findutils/findutils-4.7.0.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/tar/tar-1.32.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-8.0-patches/readline80-001{,.sig} \
		https://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0-patches/bash50-00{1..9}{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-5.0-patches/bash50-0{10..11}{,.sig} \
		https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.bz2{,.sig} \
		https://www.zsh.org/pub/zsh-5.7.1.tar.xz{,.asc}

	$(call PGP_VERIFY,source/coreutils-8.31.tar.xz)
	$(call PGP_VERIFY,source/sed-4.7.tar.xz)
	$(call PGP_VERIFY,source/grep-3.3.tar.xz)
	$(call PGP_VERIFY,source/findutils-4.7.0.tar.xz)
	$(call PGP_VERIFY,source/diffutils-3.7.tar.xz)
	$(call PGP_VERIFY,source/tar-1.32.tar.gz)
	$(call PGP_VERIFY,source/readline-8.0.tar.gz)
	$(call PGP_VERIFY,source/readline80-001)
	$(call PGP_VERIFY,source/ncurses-6.1.tar.gz)
	$(call PGP_VERIFY,source/bash-5.0.tar.gz)
	$(call PGP_VERIFY,source/bash50-001)
	$(call PGP_VERIFY,source/bash50-002)
	$(call PGP_VERIFY,source/bash50-003)
	$(call PGP_VERIFY,source/bash50-004)
	$(call PGP_VERIFY,source/bash50-005)
	$(call PGP_VERIFY,source/bash50-006)
	$(call PGP_VERIFY,source/bash50-007)
	$(call PGP_VERIFY,source/bash50-008)
	$(call PGP_VERIFY,source/bash50-009)
	$(call PGP_VERIFY,source/bash50-010)
	$(call PGP_VERIFY,source/bash50-011)
	$(call PGP_VERIFY,source/pcre-8.43.tar.bz2)
	$(call PGP_VERIFY,source/zsh-5.7.1.tar.xz,asc)

	$(call EXTRACT_TAR,source/coreutils-8.31.tar.xz,coreutils-8.31,coreutils)
	$(call EXTRACT_TAR,source/sed-4.7.tar.xz,sed-4.7,sed)
	$(call EXTRACT_TAR,source/grep-3.3.tar.xz,grep-3.3,grep)
	$(call EXTRACT_TAR,source/findutils-4.7.0.tar.xz,findutils-4.7.0,findutils)
	$(call EXTRACT_TAR,source/diffutils-3.7.tar.xz,diffutils-3.7,diffutils)
	$(call EXTRACT_TAR,source/tar-1.32.tar.gz,tar-1.32,tar)
	$(call EXTRACT_TAR,source/readline-8.0.tar.gz,readline-8.0,readline)
	$(call EXTRACT_TAR,source/ncurses-6.1.tar.gz,ncurses-6.1,ncurses)
	$(call EXTRACT_TAR,source/bash-5.0.tar.gz,bash-5.0,bash)
	$(call EXTRACT_TAR,source/pcre-8.43.tar.bz2,pcre-8.43,pcre)
	$(call EXTRACT_TAR,source/zsh-5.7.1.tar.xz,zsh-5.7.1,zsh)

	patch -p0 -d readline < source/readline80-001
	patch -p0 -d bash < source/bash50-001
	patch -p0 -d bash < source/bash50-002
	patch -p0 -d bash < source/bash50-003
	patch -p0 -d bash < source/bash50-004
	patch -p0 -d bash < source/bash50-005
	patch -p0 -d bash < source/bash50-006
	patch -p0 -d bash < source/bash50-007
	patch -p0 -d bash < source/bash50-008
	patch -p0 -d bash < source/bash50-009
	patch -p0 -d bash < source/bash50-010
	patch -p0 -d bash < source/bash50-011

	@# Copy headers from MacOSX.sdk
	mkdir -p build_base/include/sys/
	cp $(MACOSX_SYSROOT)/usr/include/sys/ttydev.h build_base/include/sys/

	@# Patch headers from iPhoneOS.sdk
	cp $(SYSROOT)/usr/include/stdlib.h build_base/include/
	$(SED) -Ei s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g build_base/include/stdlib.h

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
include ncurses.mk
include bash.mk
include pcre.mk
include zsh.mk

after-all::
	find $(DESTDIR) -type f -exec $(LDID) -S {} \;

clean::
	rm -rf dist fakeroot_persist
	rm -rf build_base/include/sys/ttydev.h build_base/include/stdlib.h build_base/include/time.h
	rm -rf coreutils sed grep findutils diffutils tar readline ncurses bash pcre zsh

.PHONY: setup clean
