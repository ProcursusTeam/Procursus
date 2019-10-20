PLATFORM        ?= iphoneos
ARCH            ?= arm64
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
GNU_HOST_TRIPLE ?= aarch64-apple-darwin

iphoneos_VERSION_MIN := -miphoneos-version-min=11.0

DEB_ARCH       := iphoneos-arm64-thin
DEB_ORIGIN     := checkra1n
DEB_MAINTAINER := checkra1n

CFLAGS  := -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -I$(PWD)/build_base/include
LDFLAGS := -L$(PWD)/build_base/lib
DESTDIR := $(PWD)/dist

export CFLAGS LDFLAGS DESTDIR

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
PGP_VERIFY  = gpg --verify $(1).sig $(1) 2>&1 | grep -q 'Good signature'

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
FAKEROOT := fakeroot -i fakeroot_persist -s fakeroot_persist --
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
	coreutils

setup:
	wget -nc \
		https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz{,.sig}
	$(call PGP_VERIFY,coreutils-8.31.tar.xz)
	$(TAR) -xf coreutils-8.31.tar.xz && mv coreutils-8.31 coreutils

	@# Note: iOS 10+ specific API
	cp $(SYSROOT)/usr/include/time.h build_base/include/
	$(SED) -Ei s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g build_base/include/time.h

export CHECKRA1N_MEMO := 1

include coreutils.mk

clean::
	rm -rf dist fakeroot_persist
	rm -rf build_base/include/time.h
	rm -rf coreutils

.PHONY: setup clean
