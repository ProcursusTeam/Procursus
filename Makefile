ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Homebrew - brew install make)
endif

SHELL           := /usr/bin/env bash
UNAME           := $(shell uname -s)
SUBPROJECTS     := \
	cacerts coreutils sed grep findutils diffutils tar readline ncurses bash berkeleydb libgpg-error libtasn1 libgmp10 libidn2 libunistring npth zstd profile.d \
	libressl openssh libgcrypt gettext p11-kit nettle libksba libassuan \
	bzip2 lz4 xz gnutls gnupg \
	pcre zsh \
	less nano \
	apt dpkg \
	uikittools darwintools system-cmds

PLATFORM        ?= iphoneos
ARCH            ?= arm64
GNU_HOST_TRIPLE ?= aarch64-apple-darwin

ifeq ($(UNAME),Linux)
$(warning Building on Linux)
SYSROOT         ?= $(HOME)/cctools/SDK/iPhoneOS13.2.sdk
MACOSX_SYSROOT  ?= $(HOME)/cctools/SDK/MacOSX.sdk

CC       := $(GNU_HOST_TRIPLE)-clang
CXX      := $(GNU_HOST_TRIPLE)-clang++
AR       := $(GNU_HOST_TRIPLE)-ar
RANLIB   := $(GNU_HOST_TRIPLE)-ranlib
STRIP    := $(GNU_HOST_TRIPLE)-strip
I_N_T    := $(GNU_HOST_TRIPLE)-install_name_tool
export CC CXX AR RANLIB STRIP

else ifeq ($(UNAME),Darwin)
$(warning Building on MacOS)
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
I_N_T           := install_name_tool
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
# Dpkg info storage area
BUILD_INFO    := $(PWD)/build_info
# Extracted source working directory
BUILD_WORK     := $(PWD)/build_work
# Bootstrap working area
BUILD_STAGE    := $(PWD)/build_stage
# Final output
BUILD_DIST     := $(PWD)/build_dist

CFLAGS          := -O2 -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include
CXXFLAGS        := $(CFLAGS)
LDFLAGS         := -L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib
PKG_CONFIG_PATH := $(BUILD_BASE)/usr/lib/pkgconfig

export PLATFORM ARCH SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE I_N_T
export BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH

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

SIGN =  find $(BUILD_DIST)/$(1) -type f -exec $(LDID) -S$(BUILD_INFO)/$(2) {} \; &> /dev/null ; \
		find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete ;
		
PACK =  $(FAKEROOT) find $(BUILD_DIST)/$(1) \( -name '*.la' -o -name '*.a' \) -type f -delete ; \
		$(FAKEROOT) rm -rf $(BUILD_DIST)/$(1)/usr/share/{info,man,aclocal,doc} ; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/* ; \
		$(FAKEROOT) mkdir -p $(BUILD_DIST)/$(1)/DEBIAN ; \
		cp $(BUILD_INFO)/$(1).control $(BUILD_DIST)/$(1)/DEBIAN/control ; \
		cp $(BUILD_INFO)/$(1).postinst $(BUILD_DIST)/$(1)/DEBIAN/postinst 2>/dev/null || : ; \
		cp $(BUILD_INFO)/$(1).preinst $(BUILD_DIST)/$(1)/DEBIAN/preinst 2>/dev/null || : ; \
		cp $(BUILD_INFO)/$(1).postrm $(BUILD_DIST)/$(1)/DEBIAN/postrm 2>/dev/null || : ; \
		cp $(BUILD_INFO)/$(1).prerm $(BUILD_DIST)/$(1)/DEBIAN/prerm 2>/dev/null || : ; \
		cp $(BUILD_INFO)/$(1).extrainst_ $(BUILD_DIST)/$(1)/DEBIAN/extrainst_ 2>/dev/null || : ; \
		chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/* ; \
		$(SED) -i ':a; s/@$(2)@/$($(2))/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control ; \
		$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control ; \
		$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control ; \
		$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/$(1)_$($(2))_$(DEB_ARCH).deb ;

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
$(shell touch .fakeroot_persist)
FAKEROOT := fakeroot -i $(PWD)/.fakeroot_persist -s $(PWD)/.fakeroot_persist --
# FAKEROOT :=
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

%-stage: %
	rm -f $(BUILD_ROOT)/.fakeroot_persist

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)/usr/{include,lib} \
		$(BUILD_WORK) $(BUILD_STAGE) $(BUILD_DIST)

	git submodule update --init --recursive

	@# TODO: lz4 + zstd + zsh no signature check
	@# Berkeleydb requires registration on Oracle's website, so this is a mirror.
	wget -nc -P $(BUILD_SOURCE) \
		https://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/sed/sed-$(SED_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/grep/grep-$(GREP_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/findutils/findutils-$(FINDUTILS_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/diffutils/diffutils-$(DIFFUTILS_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/tar/tar-$(TAR_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION)-patches/readline80-00{1..4}{,.sig} \
		https://ftp.gnu.org/gnu/ncurses/ncurses-$(NCURSES_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-$(BASH_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-$(BASH_VERSION)-patches/bash50-00{1..9}{,.sig} \
		https://ftp.gnu.org/gnu/bash/bash-$(BASH_VERSION)-patches/bash50-0{10..16}{,.sig} \
		https://sourceware.org/pub/bzip2/bzip2-$(BZIP2_VERSION).tar.gz{,.sig} \
		https://github.com/lz4/lz4/archive/v$(LZ4_VERSION).tar.gz \
		https://tukaani.org/xz/xz-$(XZ_VERSION).tar.xz{,.sig} \
		https://ftp.pcre.org/pub/pcre/pcre-$(PCRE_VERSION).tar.bz2{,.sig} \
		https://www.zsh.org/pub/zsh-$(ZSH_VERSION).tar.xz{,.asc} \
		https://ftp.gnu.org/gnu/less/less-$(LESS_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/nano/nano-$(NANO_VERSION).tar.xz{,.sig} \
		https://fossies.org/linux/misc/db-$(BDB_VERSION).tar.gz \
		https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-$(LIBRESSL_VERSION).tar.gz{,.asc} \
		https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2{,.sig} \
		https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2{,.sig} \
		https://ftp.gnu.org/pub/gnu/gettext/gettext-$(GETTEXT_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/libtasn1/libtasn1-$(LIBTASN1_VERSION).tar.gz{,.sig} \
		https://github.com/p11-glue/p11-kit/releases/download/$(P11_VERSION)/p11-kit-$(P11_VERSION).tar.xz{,.sig} \
		https://gmplib.org/download/gmp/gmp-$(GMP_VERSION).tar.xz{,.sig} \
		https://ftp.gnu.org/gnu/nettle/nettle-$(NETTLE_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/libidn/libidn2-$(IDN2_VERSION).tar.gz{,.sig} \
		https://ftp.gnu.org/gnu/libunistring/libunistring-$(UNISTRING_VERSION).tar.gz{,.sig} \
		https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-$(GNUTLS_VERSION).tar.xz{,.sig} \
		https://gnupg.org/ftp/gcrypt/libksba/libksba-$(KSBA_VERSION).tar.bz2{,.sig} \
		https://gnupg.org/ftp/gcrypt/npth/npth-$(NPTH_VERSION).tar.bz2{,.sig} \
		https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$(LIBASSUAN_VERSION).tar.bz2{,.sig} \
		https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(GNUPG_VERSION).tar.bz2{,.sig} \
		https://github.com/facebook/zstd/archive/v$(ZSTD_VERSION).tar.gz
	
	$(call PGP_VERIFY,coreutils-$(COREUTILS_VERSION).tar.xz)
	$(call PGP_VERIFY,sed-$(SED_VERSION).tar.xz)
	$(call PGP_VERIFY,grep-$(GREP_VERSION).tar.xz)
	$(call PGP_VERIFY,findutils-$(FINDUTILS_VERSION).tar.xz)
	$(call PGP_VERIFY,diffutils-$(DIFFUTILS_VERSION).tar.xz)
	$(call PGP_VERIFY,tar-$(TAR_VERSION).tar.gz)
	$(call PGP_VERIFY,readline-$(READLINE_VERSION).tar.gz)
	$(call PGP_VERIFY,readline80-001)
	$(call PGP_VERIFY,readline80-002)
	$(call PGP_VERIFY,readline80-003)
	$(call PGP_VERIFY,readline80-004)
	$(call PGP_VERIFY,ncurses-$(NCURSES_VERSION).tar.gz)
	$(call PGP_VERIFY,bash-$(BASH_VERSION).tar.gz)
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
	$(call PGP_VERIFY,bash50-012)
	$(call PGP_VERIFY,bash50-013)
	$(call PGP_VERIFY,bash50-014)
	$(call PGP_VERIFY,bash50-015)
	$(call PGP_VERIFY,bash50-016)
	$(call PGP_VERIFY,bzip2-$(BZIP2_VERSION).tar.gz)
	# $(call PGP_VERIFY,v1.9.2.tar.gz)
	$(call PGP_VERIFY,xz-$(XZ_VERSION).tar.xz)
	$(call PGP_VERIFY,pcre-$(PCRE_VERSION).tar.bz2)
	# $(call PGP_VERIFY,zsh-5.8.tar.xz,asc)
	$(call PGP_VERIFY,less-$(LESS_VERSION).tar.gz)
	$(call PGP_VERIFY,nano-$(NANO_VERSION).tar.xz)
	$(call PGP_VERIFY,libressl-$(LIBRESSL_VERSION).tar.gz,asc)
	$(call PGP_VERIFY,libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2)
	$(call PGP_VERIFY,libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2)
	$(call PGP_VERIFY,gettext-$(GETTEXT_VERSION).tar.xz)
	$(call PGP_VERIFY,libtasn1-$(LIBTASN1_VERSION).tar.gz)
	$(call PGP_VERIFY,p11-kit-$(P11_VERSION).tar.xz)
	$(call PGP_VERIFY,gmp-$(GMP_VERSION).tar.xz)
	$(call PGP_VERIFY,nettle-$(NETTLE_VERSION).tar.gz)
	$(call PGP_VERIFY,libidn2-$(IDN2_VERSION).tar.gz)
	$(call PGP_VERIFY,libunistring-$(UNISTRING_VERSION).tar.gz)
	$(call PGP_VERIFY,gnutls-$(GNUTLS_VERSION).tar.xz)
	$(call PGP_VERIFY,libksba-$(KSBA_VERSION).tar.bz2)
	$(call PGP_VERIFY,npth-$(NPTH_VERSION).tar.bz2)
	$(call PGP_VERIFY,libassuan-$(LIBASSUAN_VERSION).tar.bz2)
	$(call PGP_VERIFY,gnupg-$(GNUPG_VERSION).tar.bz2)

	$(call EXTRACT_TAR,coreutils-$(COREUTILS_VERSION).tar.xz,coreutils-$(COREUTILS_VERSION),coreutils)
	$(call EXTRACT_TAR,sed-$(SED_VERSION).tar.xz,sed-$(SED_VERSION),sed)
	$(call EXTRACT_TAR,grep-$(GREP_VERSION).tar.xz,grep-$(GREP_VERSION),grep)
	$(call EXTRACT_TAR,findutils-$(FINDUTILS_VERSION).tar.xz,findutils-$(FINDUTILS_VERSION),findutils)
	$(call EXTRACT_TAR,diffutils-$(DIFFUTILS_VERSION).tar.xz,diffutils-$(DIFFUTILS_VERSION),diffutils)
	$(call EXTRACT_TAR,tar-$(TAR_VERSION).tar.gz,tar-$(TAR_VERSION),tar)
	$(call EXTRACT_TAR,readline-$(READLINE_VERSION).tar.gz,readline-$(READLINE_VERSION),readline)
	$(call EXTRACT_TAR,ncurses-$(NCURSES_VERSION).tar.gz,ncurses-$(NCURSES_VERSION),ncurses)
	$(call EXTRACT_TAR,bash-$(BASH_VERSION).tar.gz,bash-$(BASH_VERSION),bash)
	$(call EXTRACT_TAR,bzip2-$(BZIP2_VERSION).tar.gz,bzip2-$(BZIP2_VERSION),bzip2)
	$(call EXTRACT_TAR,v$(LZ4_VERSION).tar.gz,lz4-$(LZ4_VERSION),lz4)
	$(call EXTRACT_TAR,xz-$(XZ_VERSION).tar.xz,xz-$(XZ_VERSION),xz)
	$(call EXTRACT_TAR,pcre-$(PCRE_VERSION).tar.bz2,pcre-$(PCRE_VERSION),pcre)
	$(call EXTRACT_TAR,zsh-$(ZSH_VERSION).tar.xz,zsh-$(ZSH_VERSION),zsh)
	$(call EXTRACT_TAR,less-$(LESS_VERSION).tar.gz,less-$(LESS_VERSION),less)
	$(call EXTRACT_TAR,nano-$(NANO_VERSION).tar.xz,nano-$(NANO_VERSION),nano)
	$(call EXTRACT_TAR,db-$(BDB_VERSION).tar.gz,db-$(BDB_VERSION),berkeleydb)
	$(call EXTRACT_TAR,libressl-$(LIBRESSL_VERSION).tar.gz,libressl-$(LIBRESSL_VERSION),libressl)
	$(call EXTRACT_TAR,libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2,libgpg-error-$(LIBGPG-ERROR_VERSION),libgpg-error)
	$(call EXTRACT_TAR,libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2,libgcrypt-$(LIBGCRYPT_VERSION),libgcrypt)
	$(call EXTRACT_TAR,gettext-$(GETTEXT_VERSION).tar.xz,gettext-$(GETTEXT_VERSION),gettext)
	$(call EXTRACT_TAR,libtasn1-$(LIBTASN1_VERSION).tar.gz,libtasn1-$(LIBTASN1_VERSION),libtasn1)
	$(call EXTRACT_TAR,p11-kit-$(P11_VERSION).tar.xz,p11-kit-$(P11_VERSION),p11-kit)
	$(call EXTRACT_TAR,gmp-$(GMP_VERSION).tar.xz,gmp-$(GMP_VERSION),libgmp10)
	$(call EXTRACT_TAR,nettle-$(NETTLE_VERSION).tar.gz,nettle-$(NETTLE_VERSION),nettle)
	$(call EXTRACT_TAR,libidn2-$(IDN2_VERSION).tar.gz,libidn2-$(IDN2_VERSION),libidn2)
	$(call EXTRACT_TAR,libunistring-$(UNISTRING_VERSION).tar.gz,libunistring-$(UNISTRING_VERSION),libunistring)
	$(call EXTRACT_TAR,gnutls-$(GNUTLS_VERSION).tar.xz,gnutls-$(GNUTLS_VERSION),gnutls)
	$(call EXTRACT_TAR,libksba-$(KSBA_VERSION).tar.bz2,libksba-$(KSBA_VERSION),libksba)
	$(call EXTRACT_TAR,npth-$(NPTH_VERSION).tar.bz2,npth-$(NPTH_VERSION),npth)
	$(call EXTRACT_TAR,libassuan-$(LIBASSUAN_VERSION).tar.bz2,libassuan-$(LIBASSUAN_VERSION),libassuan)
	$(call EXTRACT_TAR,gnupg-$(GNUPG_VERSION).tar.bz2,gnupg-$(GNUPG_VERSION),gnupg)
	$(call EXTRACT_TAR,v$(ZSTD_VERSION).tar.gz,zstd-$(ZSTD_VERSION),zstd)

	$(call DO_PATCH,readline80-001,readline,-p0)
	$(call DO_PATCH,readline80-002,readline,-p0)
	$(call DO_PATCH,readline80-003,readline,-p0)
	$(call DO_PATCH,readline80-004,readline,-p0)
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
	$(call DO_PATCH,bash50-012,bash,-p0)
	$(call DO_PATCH,bash50-013,bash,-p0)
	$(call DO_PATCH,bash50-014,bash,-p0)
	$(call DO_PATCH,bash50-015,bash,-p0)
	$(call DO_PATCH,bash50-016,bash,-p0)

	@# Copy headers from MacOSX.sdk
	rm -rf $(BUILD_BASE)/usr/include/libkern
	mkdir -p $(BUILD_BASE)/usr/include/{IOKit,sys,xpc,net,servers,libkern.bad}
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/ttydev.h $(BUILD_BASE)/usr/include/sys/
	cp -rf $(MACOSX_SYSROOT)/usr/include/ar.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/xpc/* $(BUILD_BASE)/usr/include/xpc
	cp -rf $(MACOSX_SYSROOT)/usr/include/launch.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/libc.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/libproc.h $(BUILD_BASE)/usr/include/
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/proc*.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/kern_control.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/net/* $(BUILD_BASE)/usr/include/net
	cp -rf $(MACOSX_SYSROOT)/usr/include/servers/* $(BUILD_BASE)/usr/include/servers
	cp -rf $(MACOSX_SYSROOT)/usr/include/bootstrap*.h $(BUILD_BASE)/usr/include
	cp -rf $(MACOSX_SYSROOT)/usr/include/NSSystemDirectories.h $(BUILD_BASE)/usr/include/NSSystemDirectories.h
	cp -rf $(MACOSX_SYSROOT)/usr/include/sys/reboot.h $(BUILD_BASE)/usr/include/sys
	cp -rf $(MACOSX_SYSROOT)/usr/include/tzfile.h $(BUILD_BASE)/usr/include
	cp -rf $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/usr/include/IOKit
	cp -rf $(MACOSX_SYSROOT)/usr/include/libkern/* $(BUILD_BASE)/usr/include/libkern.bad
	
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
	rm -rf $(BUILD_BASE) $(BUILD_WORK) $(BUILD_STAGE)
	@# When using 'make clean' in submodules, there is still an issue with the subproject changing when committing. This fixes that.
	git submodule foreach --recursive git clean -xfd
	git submodule foreach --recursive git reset --hard
	rm -f darwintools/.build_complete
	$(MAKE) -C darwintools clean

.PHONY: clean setup
