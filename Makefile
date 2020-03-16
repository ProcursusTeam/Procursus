ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Homebrew - brew install make)
endif

SHELL           := /usr/bin/env bash
UNAME           := $(shell uname -s)
SUBPROJECTS     := \
	coreutils sed grep findutils diffutils tar readline ncurses bash berkeleydb libgpg-error\
	libressl openssh libgcrypt gettext \
	bzip2 lz4 xz \
	pcre zsh \
	less nano \
	apt dpkg \
	uikittools darwintools system-cmds

PLATFORM        ?= iphoneos
ARCH            ?= arm64
GNU_HOST_TRIPLE ?= aarch64-apple-darwin

ifeq ($(UNAME),Linux)
$(warning Building on Linux)
TRIPLE          ?= arm-apple-darwin17
SYSROOT         ?= $(HOME)/cctools/SDK/iPhoneOS13.2.sdk
MACOSX_SYSROOT  ?= $(HOME)/cctools/SDK/MacOSX.sdk

CC       := $(GNU_HOST_TRIPLE)-clang
CXX      := $(GNU_HOST_TRIPLE)-clang++
AR       := $(GNU_HOST_TRIPLE)-ar
RANLIB   := $(GNU_HOST_TRIPLE)-ranlib
STRIP    := $(GNU_HOST_TRIPLE)-strip

export CC CXX AR RANLIB STRIP

else ifeq ($(UNAME),Darwin)
$(warning Building on MacOS)
TRIPLE          ?=
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
else
$(error Please use Linux or MacOS to build)
endif

iphoneos_VERSION_MIN := -miphoneos-version-min=11.0

DEB_ARCH       := iphoneos-arm
DEB_ORIGIN     := checkra1n
DEB_MAINTAINER := checkra1n

# Root
BUILD_ROOT     := $(PWD)
# Downloaded source files
BUILD_SOURCE   := $(PWD)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     := $(PWD)/build_base
# Extracted source working directory
BUILD_WORK     := $(PWD)/build_work
# Bootstrap working area
BUILD_STAGE    := $(PWD)/build_stage
# Final output
BUILD_DIST     := $(PWD)/build_dist

CFLAGS   := -O2 -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include
CXXFLAGS := $(CFLAGS)
LDFLAGS  := -L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib

export PLATFORM ARCH TRIPLE SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE
export BUILD_BASE BUILD_WORK BUILD_STAGE BUILD_DIST
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS LDFLAGS

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
PGP_VERIFY  = gpg --verify $(BUILD_SOURCE)/$(1).$(if $(2),$(2),sig) $(BUILD_SOURCE)/$(1) 2>&1 | grep -q 'Good signature'

EXTRACT_TAR = if [ ! -d $(BUILD_WORK)/$(3) ]; then \
		cd $(BUILD_WORK) && \
		$(TAR) -xf $(BUILD_SOURCE)/$(1) && \
		mv $(2) $(3); \
	fi

DO_PATCH    = if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $(1)).done ]; then \
		$(PATCH) -sN -d $(BUILD_WORK)/$(2) $(3) < $(BUILD_SOURCE)/$(1); \
		touch $(BUILD_WORK)/$(2)/$(notdir $(1)).done; \
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

ifeq ($(call HAS_COMMAND,gpatch),1)
PATCH := gpatch
else ifeq ($(shell patch --version | grep -q 'GNU patch' && echo 1),1)
PATCH := patch
else
$(error Install GNU patch)
endif

ifeq ($(call HAS_COMMAND,grmdir),1)
RMDIR := grmdir
else ifeq ($(shell rmdir --version | grep -q 'GNU coreutils' && echo 1),1)
RMDIR := rmdir
else
$(error Install GNU coreutils)
endif

ifeq ($(call HAS_COMMAND,gln),1)
LN := gln
else ifeq ($(shell ln --version | grep -q 'GNU coreutils' && echo 1),1)
LN := ln
else
$(error Install GNU coreutils)
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

ifneq ($(call HAS_COMMAND,autopoint),1)
ifeq ($(call HAS_COMMAND,$(shell brew --prefix)/opt/gettext/bin/autopoint),1)
PATH += :$(shell brew --prefix)/opt/gettext/bin
else
$(error Install gettext)
endif
endif

MAKEFLAGS += --no-print-directory

ifeq ($(findstring --jobserver-auth=,$(MAKEFLAGS)),)
ifeq ($(call HAS_COMMAND,nproc),1)
GET_LOGICAL_CORES := nproc
else
GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
MAKEFLAGS += -j$(shell $(GET_LOGICAL_CORES)) -Otarget
endif

all:: setup $(SUBPROJECTS) package
package:: $(SUBPROJECTS:%=%-package)

CHECKRA1N_MEMO := 1

$(foreach proj,$(SUBPROJECTS),$(eval include $(proj).mk))

%-package: %-stage
	@echo TODO $@ $<

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)/usr/{include,lib} \
		$(BUILD_WORK) $(BUILD_STAGE) $(BUILD_DIST)

	git submodule update --init --recursive

	@# TODO: lz4 + zsh no signature check
	@# Berkeleydb requires registration on Oracle's website, so this is a mirror.
	wget -nc -P $(BUILD_SOURCE) \
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
		https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz{,.sig} \
		https://github.com/lz4/lz4/archive/v1.9.2.tar.gz \
		https://tukaani.org/xz/xz-5.2.4.tar.xz{,.sig} \
		https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.bz2{,.sig} \
		https://www.zsh.org/pub/zsh-5.8.tar.xz{,.asc} \
		https://ftp.gnu.org/gnu/less/less-530.tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/nano/nano-4.5.tar.xz{,.sig} \
		https://fossies.org/linux/misc/db-18.1.32.tar.gz \
		https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.0.2.tar.gz{,.asc} \
		https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.37.tar.bz2{,.sig} \
		https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.5.tar.bz2{,.sig} \
		https://ftp.gnu.org/pub/gnu/gettext/gettext-0.20.1.tar.xz{,.sig}
	
	$(call PGP_VERIFY,coreutils-8.31.tar.xz)
	$(call PGP_VERIFY,sed-4.7.tar.xz)
	$(call PGP_VERIFY,grep-3.3.tar.xz)
	$(call PGP_VERIFY,findutils-4.7.0.tar.xz)
	$(call PGP_VERIFY,diffutils-3.7.tar.xz)
	$(call PGP_VERIFY,tar-1.32.tar.gz)
	$(call PGP_VERIFY,readline-8.0.tar.gz)
	$(call PGP_VERIFY,readline80-001)
	$(call PGP_VERIFY,ncurses-6.1.tar.gz)
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
	$(call PGP_VERIFY,bzip2-1.0.8.tar.gz)
	# $(call PGP_VERIFY,v1.9.2.tar.gz)
	$(call PGP_VERIFY,xz-5.2.4.tar.xz)
	$(call PGP_VERIFY,pcre-8.43.tar.bz2)
	# $(call PGP_VERIFY,zsh-5.8.tar.xz,asc)
	$(call PGP_VERIFY,less-530.tar.gz)
	$(call PGP_VERIFY,nano-4.5.tar.xz)
	$(call PGP_VERIFY,libressl-3.0.2.tar.gz,asc)
	$(call PGP_VERIFY,libgpg-error-1.37.tar.bz2)
	$(call PGP_VERIFY,libgcrypt-1.8.5.tar.bz2)
	$(call PGP_VERIFY,gettext-0.20.1.tar.xz)

	$(call EXTRACT_TAR,coreutils-8.31.tar.xz,coreutils-8.31,coreutils)
	$(call EXTRACT_TAR,sed-4.7.tar.xz,sed-4.7,sed)
	$(call EXTRACT_TAR,grep-3.3.tar.xz,grep-3.3,grep)
	$(call EXTRACT_TAR,findutils-4.7.0.tar.xz,findutils-4.7.0,findutils)
	$(call EXTRACT_TAR,diffutils-3.7.tar.xz,diffutils-3.7,diffutils)
	$(call EXTRACT_TAR,tar-1.32.tar.gz,tar-1.32,tar)
	$(call EXTRACT_TAR,readline-8.0.tar.gz,readline-8.0,readline)
	$(call EXTRACT_TAR,ncurses-6.1.tar.gz,ncurses-6.1,ncurses)
	$(call EXTRACT_TAR,bash-5.0.tar.gz,bash-5.0,bash)
	$(call EXTRACT_TAR,bzip2-1.0.8.tar.gz,bzip2-1.0.8,bzip2)
	$(call EXTRACT_TAR,v1.9.2.tar.gz,lz4-1.9.2,lz4)
	$(call EXTRACT_TAR,xz-5.2.4.tar.xz,xz-5.2.4,xz)
	$(call EXTRACT_TAR,pcre-8.43.tar.bz2,pcre-8.43,pcre)
	$(call EXTRACT_TAR,zsh-5.8.tar.xz,zsh-5.8,zsh)
	$(call EXTRACT_TAR,less-530.tar.gz,less-530,less)
	$(call EXTRACT_TAR,nano-4.5.tar.xz,nano-4.5,nano)
	$(call EXTRACT_TAR,db-18.1.32.tar.gz,db-18.1.32,berkeleydb)
	$(call EXTRACT_TAR,libressl-3.0.2.tar.gz,libressl-3.0.2,libressl)
	$(call EXTRACT_TAR,libgpg-error-1.37.tar.bz2,libgpg-error-1.37,libgpg-error)
	$(call EXTRACT_TAR,libgcrypt-1.8.5.tar.bz2,libgcrypt-1.8.5,libgcrypt)
	$(call EXTRACT_TAR,gettext-0.20.1.tar.xz,gettext-0.20.1,gettext)

	$(call DO_PATCH,readline80-001,readline,-p0)
	$(call DO_PATCH,bash50-001,bash,-p0)
	$(call DO_PATCH,bash50-002,bash,-p0)
	$(call DO_PATCH,bash50-003,bash,-p0)
	$(call DO_PATCH,bash50-004,bash,-p0)
	$(call DO_PATCH,bash50-005,bash,-p0)
	$(call DO_PATCH,bash50-006,bash,-p0)
	$(call DO_PATCH,bash50-007,bash,-p0)
	$(call DO_PATCH,bash50-008,bash,-p0)
	$(call DO_PATCH,bash50-009,bash,-p0)
	$(call DO_PATCH,bash50-010,bash,-p0)
	$(call DO_PATCH,bash50-011,bash,-p0)

	@# Copy headers from MacOSX.sdk
	mkdir -p $(BUILD_BASE)/usr/include/sys/
	mkdir -p $(BUILD_BASE)/usr/include/IOKit
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/ttydev.h $(BUILD_BASE)/usr/include/sys/
	cp -rf $(MACOSX_SYSROOT)/usr/include/ar.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/xpc $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/launch.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/libc.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/libproc.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/proc*.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/kern_control.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/net $(BUILD_BASE)/usr/include/net
	cp -rf $(MACOSX_SYSROOT)/usr/include/servers $(BUILD_BASE)/usr/include/servers
	cp -rf $(MACOSX_SYSROOT)/usr/include/bootstrap*.h $(BUILD_BASE)/usr/include
	cp -rf $(MACOSX_SYSROOT)/usr/include/NSSystemDirectories.h $(BUILD_BASE)/usr/include/NSSystemDirectories.h
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/reboot.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/tzfile.h $(BUILD_BASE)/usr/include
	cp -rf $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/usr/include/IOKit
	cp -rf $(MACOSX_SYSROOT)/usr/include/libkern $(BUILD_BASE)/usr/include/libkern
	
	@# Download extra headers that aren't included in MacOSX.sdk

	wget -nc -P $(BUILD_BASE)/usr/include \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/bootstrap_priv.h \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/reboot2.h

	@# Patch headers from iPhoneOS.sdk
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)/usr/include/stdlib.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(SYSROOT)/usr/include/time.h > $(BUILD_BASE)/usr/include/time.h

after-all::
	# find $(DESTDIR) -type f -exec $(LDID) -S {} \; 2>&1 | grep -v '_assert(false); errno=0'

clean::
	rm -rf $(BUILD_BASE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_DIST)
	@# When using 'make clean' in submodules, there is still an issue with the subproject changing when committing. This fixes that.
	git submodule foreach --recursive git clean -xfd
	git submodule foreach --recursive git reset --hard
	rm -f darwintools/.build_complete
	$(MAKE) -C darwintools clean

.PHONY: clean setup
