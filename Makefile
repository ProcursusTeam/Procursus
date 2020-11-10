ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Homebrew - brew install make)
endif

ifeq ($(shell /usr/bin/env bash --version | grep -q 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

UNAME           := $(shell uname -s)
SUBPROJECTS     += $(STRAPPROJECTS)

ifneq ($(shell umask),0022)
$(error Please run `umask 022` before running this)
endif

MEMO_TARGET          ?= iphoneos-arm64
MEMO_CFVER           ?= 1600
# iOS 13.0 == 1665.15.
CFVER_WHOLE          := $(shell echo $(MEMO_CFVER) | cut -d. -f1)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1100 ] && [ "$(CFVER_WHOLE)" -lt 1200 ] && echo 1),1)
IPHONE_MIN           := 8.0
TVOS_MIN             := XXX
WATCH_MIN            := 1.0
override MEMO_CFVER  := 1100
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1200 ] && [ "$(CFVER_WHOLE)" -lt 1300 ] && echo 1),1)
IPHONE_MIN           := 9.0
TVOS_MIN             := 9.0
WATCH_MIN            := 2.0
override MEMO_CFVER  := 1200
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1300 ] && [ "$(CFVER_WHOLE)" -lt 1400 ] && echo 1),1)
IPHONE_MIN           := 10.0
TVOS_MIN             := 10.0
WATCH_MIN            := 3.0
override MEMO_CFVER  := 1300
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
IPHONE_MIN           := 11.0
TVOS_MIN             := 11.0
WATCH_MIN            := 4.0
override MEMO_CFVER  := 1400
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1500 ] && [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
IPHONE_MIN           := 12.0
TVOS_MIN             := 12.0
WATCH_MIN            := 5.0
override MEMO_CFVER  := 1500
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
IPHONE_MIN           := 13.0
TVOS_MIN             := 13.0
WATCH_MIN            := 6.0
override MEMO_CFVER  := 1600
else
$(error Unsupported CoreFoundation version)
endif

ifeq ($(MEMO_TARGET),iphoneos-arm)
$(warning Building for iOS)
ARCHES               := armv7
PLATFORM             := iphoneos
DEB_ARCH             := iphoneos-arm
GNU_HOST_TRIPLE      := armv7-apple-darwin
PLATFORM_VERSION_MIN := -miphoneos-version-min=$(IPHONE_MIN)

else ifeq ($(MEMO_TARGET),iphoneos-arm64)
$(warning Building for iOS)
ARCHES               := arm64
PLATFORM             := iphoneos
DEB_ARCH             := iphoneos-arm
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -miphoneos-version-min=$(IPHONE_MIN)

else ifeq ($(MEMO_TARGET),appletvos-arm64)
$(warning Building for tvOS)
ARCHES               := arm64
PLATFORM             := appletvos
DEB_ARCH             := appletvos-arm64
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mappletvos-version-min=$(TVOS_MIN)

else ifeq ($(MEMO_TARGET),watchos-arm)
$(warning Building for WatchOS)
ARCHES               := armv7k
PLATFORM             := watchos
DEB_ARCH             := watchos-arm
GNU_HOST_TRIPLE      := armv7k-apple-darwin
PLATFORM_VERSION_MIN := -mwatchos-version-min=$(WATCH_MIN)

else ifeq ($(MEMO_TARGET),watchos-arm64)
$(warning Building for WatchOS)
ARCHES               := arm64_32
PLATFORM             := watchos
DEB_ARCH             := watchos-arm
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mwatchos-version-min=$(WATCH_MIN)

else
$(error Platform not supported)
endif

ARCH := $(shell echo $(ARCHES) | awk -F' ' '{ for(i=1;i<=NF;i++) print "-arch " $$i }' ORS=" ")

ifeq ($(UNAME),Linux)
$(warning Building on Linux)
TARGET_SYSROOT  ?= $(HOME)/cctools/SDK/iPhoneOS13.2.sdk
MACOSX_SYSROOT  ?= $(HOME)/cctools/SDK/MacOSX.sdk

CC       := $(GNU_HOST_TRIPLE)-clang
CXX      := $(GNU_HOST_TRIPLE)-clang++
CPP      := $(GNU_HOST_TRIPLE)-clang -E
AR       := $(GNU_HOST_TRIPLE)-ar
RANLIB   := $(GNU_HOST_TRIPLE)-ranlib
STRIP    := $(GNU_HOST_TRIPLE)-strip
I_N_T    := $(GNU_HOST_TRIPLE)-install_name_tool
NM       := $(GNU_HOST_TRIPLE)-nm
LIPO     := $(GNU_HOST_TRIPLE)-lipo
OTOOL    := $(GNU_HOST_TRIPLE)-otool
EXTRA    := INSTALL="/usr/bin/install -c --strip-program=$(STRIP)"
export CC CXX AR

else ifeq ($(UNAME),Darwin)
ifeq ($(filter $(shell uname -m | cut -c -4), iPad iPho),)
$(warning Building on MacOS)
TARGET_SYSROOT  ?= $(shell xcrun --sdk $(PLATFORM) --show-sdk-path)
MACOSX_SYSROOT  ?= $(shell xcrun --show-sdk-path)
CPP             := cc -E

else
$(warning Building on iOS)
TARGET_SYSROOT  ?= /usr/share/SDKs/iPhoneOS.sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CPP             := clang -E

endif
PATH            := /usr/bin:$(PATH)
RANLIB          := ranlib
STRIP           := strip
NM              := nm
LIPO            := lipo
OTOOL           := otool
I_N_T           := install_name_tool
EXTRA           :=

else
$(error Please use Linux or MacOS to build)
endif

DEB_MAINTAINER ?= Hayden Seay <me@diatr.us>

# Root
BUILD_ROOT     ?= $(PWD)
# Downloaded source files
BUILD_SOURCE   := $(BUILD_ROOT)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     := $(BUILD_ROOT)/build_base/$(MEMO_TARGET)/$(MEMO_CFVER)
# Dpkg info storage area
BUILD_INFO     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_info
# Patch storage area
BUILD_PATCH    := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_patch
# Extracted source working directory
BUILD_WORK     := $(BUILD_ROOT)/build_work/$(MEMO_TARGET)/$(MEMO_CFVER)
# Bootstrap working area
BUILD_STAGE    := $(BUILD_ROOT)/build_stage/$(MEMO_TARGET)/$(MEMO_CFVER)
# Final output
BUILD_DIST     := $(BUILD_ROOT)/build_dist/$(MEMO_TARGET)/$(MEMO_CFVER)
# Actual bootrap staging
BUILD_STRAP    := $(BUILD_ROOT)/build_strap/$(MEMO_TARGET)/$(MEMO_CFVER)
# Extra scripts for the buildsystem
BUILD_TOOLS    := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_tools

CFLAGS              := -O2 $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include -F$(BUILD_BASE)/System/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
CPPFLAGS            := -O2 -arch $(shell echo $(ARCHES) | cut -f1 -d' ') $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include
LDFLAGS             := -O2 $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks
PKG_CONFIG_PATH     := $(BUILD_BASE)/usr/lib/pkgconfig:$(BUILD_BASE)/usr/local/lib/pkgconfig

export PLATFORM ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA SED
export BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG_PATH

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
ifeq ($(NO_PGP),1)
PGP_VERIFY  = echo "Skipping verification of $(1) because NO_PGP was set to 1."
else
PGP_VERIFY  = KEY=$$(gpg --verify --status-fd 1 $(BUILD_SOURCE)/$(1).$(if $(2),$(2),sig) | grep NO_PUBKEY | cut -f3 -d' '); \
	if [ ! -z "$$KEY" ]; then \
		gpg --keyserver hkps://keyserver.ubuntu.com/ --recv-keys $$KEY; \
	fi; \
	gpg --verify $(BUILD_SOURCE)/$(1).$(if $(2),$(2),sig) $(BUILD_SOURCE)/$(1) 2>&1 | grep -q 'Good signature'
endif

EXTRACT_TAR = -if [ ! -d $(BUILD_WORK)/$(3) ] || [ "$(4)" = "1" ]; then \
		cd $(BUILD_WORK) && \
		$(TAR) -xf $(BUILD_SOURCE)/$(1) && \
		mkdir -p $(3); \
		$(CP) -af $(2)/. $(3); \
		rm -rf $(2); \
	fi; \
	find $(BUILD_BASE)/usr -name "*.la" -type f -delete

DO_PATCH    = -cd $(BUILD_PATCH)/$(1); \
	rm -f ./series; \
	for PATCHFILE in *; do \
		if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done ]; then \
			patch -sN -d $(BUILD_WORK)/$(2) $(3) < $$PATCHFILE; \
			if [ $(4) ]; then \
				patch -sN -d $(BUILD_WORK)/$(2) $(4) < $$PATCHFILE; \
			fi; \
			touch $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done; \
		fi; \
	done

SIGN =  find $(BUILD_DIST)/$(1) -type f -exec $(LDID) -S$(BUILD_INFO)/$(2) {} \; &> /dev/null; \
	find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete

PACK = -find $(BUILD_DIST)/$(1) -name '*.la' -type f -delete; \
	rm -rf $(BUILD_DIST)/$(1)/usr/share/{info,doc}; \
	find $(BUILD_DIST)/$(1)/usr/share/man -type f -exec zstd -19 --rm '{}' \; 2> /dev/null; \
	if [ -z $(3) ]; then \
		echo Setting $(1) owner to 0:0.; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/* &>/dev/null; \
	elif [ $(3) = "2" ]; then \
		echo $(1) owner set within individual makefile.; \
	fi; \
	if [ -d "$(BUILD_DIST)/$(1)/usr/share/locale" ] && [ ! "$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')" = "gettext-localizations" ]; then \
		rm -rf $(BUILD_DIST)/$(1)/usr/share/locale/*/LC_TIME; \
		$(CP) -af $(BUILD_DIST)/$(1)/usr/share/locale $(BUILD_DIST)/$(1)-locales; \
		rm -rf $(BUILD_DIST)/$(1)/usr/share/locale; \
	fi; \
	SIZE=$$(du -s $(BUILD_DIST)/$(1) | cut -f 1); \
	mkdir -p $(BUILD_DIST)/$(1)/DEBIAN; \
	$(CP) $(BUILD_INFO)/$(1).control $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(CP) $(BUILD_INFO)/$(1).postinst $(BUILD_DIST)/$(1)/DEBIAN/postinst; \
	$(CP) $(BUILD_INFO)/$(1).preinst $(BUILD_DIST)/$(1)/DEBIAN/preinst; \
	$(CP) $(BUILD_INFO)/$(1).postrm $(BUILD_DIST)/$(1)/DEBIAN/postrm; \
	$(CP) $(BUILD_INFO)/$(1).prerm $(BUILD_DIST)/$(1)/DEBIAN/prerm; \
	$(CP) $(BUILD_INFO)/$(1).extrainst_ $(BUILD_DIST)/$(1)/DEBIAN/extrainst_; \
	$(SED) -i ':a; s/@$(2)@/$($(2))/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	if [ -d "$(BUILD_DIST)/$(1)-locales" ]; then \
		$(call PACK_LOCALE,$(1)); \
	fi; \
	cd $(BUILD_DIST)/$(1) && $(FIND) . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	echo "Installed-Size: $$SIZE"; \
	echo "Installed-Size: $$SIZE" >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
	find $(BUILD_DIST)/$(1) -name '.DS_Store' -type f -delete; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')_$($(2))_$(DEB_ARCH).deb

PACK_LOCALE = mkdir -p $(BUILD_DIST)/$(1)-locale/{DEBIAN,usr/share}; \
	$(CP) -af $(BUILD_DIST)/$(1)-locales $(BUILD_DIST)/$(1)-locale/usr/share/locale; \
	rm -rf $(BUILD_DIST)/$(1)-locales; \
	rm -f $(BUILD_DIST)/$(1)-locale/usr/share/locale/locale.alias; \
	LSIZE=$$(du -s $(BUILD_DIST)/$(1)-locale | cut -f 1); \
	$(CP) $(BUILD_DIST)/$(1)/DEBIAN/control $(BUILD_DIST)/$(1)-locale/DEBIAN; \
	VERSION=$$(grep Version: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d " "); \
	$(SED) -i "s/^Depends:.*/Depends: $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d " ") (= $$VERSION), gettext-localizations/" $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Package:.*/Package: $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d " ")-locale/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Priority:.*/Priority: optional/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Section:.*/Section: Localizations/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Description:.*/Description: Locale files for $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')./' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i -e '/^Name:/d' -e '/^Provides:/d' -e '/^Replaces:/d' -e '/^Conflicts:/d' -e '/^Tag:/d' -e '/^Essential:/d' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	echo "Installed-Size: $$LSIZE" >> $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1)-locale $(BUILD_DIST)/$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')-locale_$${VERSION}_$(DEB_ARCH).deb; \
	rm -rf $(BUILD_DIST)/$(1)-locale

ifeq ($(call HAS_COMMAND,shasum),1)
GET_SHA1   = shasum -a 1 $(1) | cut -c1-40
GET_SHA256 = shasum -a 256 $(1) | cut -c1-64
else
GET_SHA1   = sha1sum $(1) | cut -c1-40
GET_SHA256 = sha256sum $(1) | cut -c1-64
endif

ifneq ($(call HAS_COMMAND,wget),1)
$(error Install wget)
endif

ifeq ($(call HAS_COMMAND,gmake),1)
PATH := $(shell brew --prefix)/opt/make/libexec/gnubin:$(PATH)
endif

ifeq ($(call HAS_COMMAND,gtar),1)
PATH := $(shell brew --prefix)/opt/gnu-tar/libexec/gnubin:$(PATH)
TAR  := tar
else ifeq ($(shell tar --version | grep -q GNU && echo 1),1)
TAR  := tar
else
$(error Install GNU tar)
endif

SED  := sed

ifeq ($(call HAS_COMMAND,gsed),1)
PATH := $(shell brew --prefix)/opt/gnu-sed/libexec/gnubin:$(PATH)
else ifneq ($(shell sed --version | grep -q GNU && echo 1),1)
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

ifeq ($(call HAS_COMMAND,libtoolize),1)
LIBTOOLIZE := libtoolize
else ifeq ($(call HAS_COMMAND,glibtoolize),1)
LIBTOOLIZE := glibtoolize
else
$(error Install libtool)
endif

ifneq ($(call HAS_COMMAND,cmake),1)
$(error Install cmake)
endif

ifneq ($(call HAS_COMMAND,pkg-config),1)
$(error Install pkg-config)
endif

ifneq ($(call HAS_COMMAND,automake),1)
$(error Install automake)
endif

ifneq (,$(wildcard $(shell brew --prefix)/opt/groff/bin))
PATH := $(shell brew --prefix)/opt/groff/bin:$(PATH)
else ifneq ($(shell groff --version | grep -q 'version 1.2' && echo 1),1)
$(error Install newer groff)
endif

ifneq (,$(wildcard $(shell brew --prefix)/opt/gpatch/bin))
PATH := $(shell brew --prefix)/opt/gpatch/bin:$(PATH)
else ifneq ($(shell patch --version | grep -q 'GNU patch' && echo 1),1)
$(error Install GNU patch)
endif

ifeq ($(call HAS_COMMAND,gfind),1)
FIND := gfind
else ifeq ($(shell find --version | grep -q 'GNU find' && echo 1),1)
FIND := find
else
$(error Install GNU findutils)
endif

ifeq ($(call HAS_COMMAND,grmdir),1)
RMDIR := grmdir
else ifeq ($(shell rmdir --version | grep -q 'GNU coreutils' && echo 1),1)
RMDIR := rmdir
else
$(error Install GNU coreutils)
endif

ifeq ($(call HAS_COMMAND,ginstall),1)
GINSTALL := ginstall
else ifeq ($(shell install --version | grep -q 'GNU coreutils' && echo 1),1)
GINSTALL := install
else
$(error Install GNU coreutils)
endif

ifeq ($(call HAS_COMMAND,gwc),1)
WC := gwc
else ifeq ($(shell wc --version | grep -q 'GNU coreutils' && echo 1),1)
WC := wc
else
$(error Install GNU coreutils)
endif

ifeq ($(call HAS_COMMAND,gcp),1)
CP := gcp
else ifeq ($(shell cp --version | grep -q 'GNU coreutils' && echo 1),1)
CP := cp
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

ifneq ($(call HAS_COMMAND,fakeroot),1)
$(error Install fakeroot)
endif

ifneq ($(call HAS_COMMAND,zstd),1)
$(error Install zstd)
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

ifneq ($(shell tic -V | grep -q 'ncurses 6' && echo 1),1)
ifeq ($(call HAS_COMMAND,$(shell brew --prefix)/opt/ncurses/bin/tic),1)
TIC_PATH := $(shell brew --prefix)/opt/ncurses/bin/tic
export TIC_PATH
else
$(error Install ncurses 6)
endif
endif

ifneq ($(LEAVE_ME_ALONE),1)

ifneq (,$(wildcard $(shell brew --prefix)/opt/docbook-xsl/docbook-xsl))
DOCBOOK_XSL := $(shell brew --prefix)/opt/docbook-xsl/docbook-xsl
else ifneq (,$(wildcard /usr/share/xml/docbook/stylesheet/docbook-xsl))
DOCBOOK_XSL := /usr/share/xml/docbook/stylesheet/docbook-xsl
else
$(error Install docbook-xsl)
endif

ifneq ($(call HAS_COMMAND,yacc),1)
$(error Install bison)
endif

ifneq ($(call HAS_COMMAND,lex),1)
$(error Install flex)
endif

ifneq ($(call HAS_COMMAND,po4a),1)
$(error Install po4a)
endif

endif

PATH := $(BUILD_TOOLS):$(PATH)

MAKEFLAGS += --no-print-directory

ifeq ($(findstring --jobserver-auth=,$(MAKEFLAGS)),)
ifeq ($(call HAS_COMMAND,nproc),1)
GET_LOGICAL_CORES := nproc
else
GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
MAKEFLAGS += --jobs=$(shell $(GET_LOGICAL_CORES))
endif

PROCURSUS := 1

all:: package
	@echo "********** Successfully built debs for $(MEMO_TARGET) **********"
	@echo "$(SUBPROJECTS)"
	@MEMO_TARGET="$(MEMO_TARGET)" MEMO_CFVER="$(MEMO_CFVER)" '$(BUILD_TOOLS)/check_gettext.sh'

everything::
	+unset SYSROOT && $(MAKE) MEMO_TARGET=watchos-arm MEMO_CFVER=1400 rebuild-all
	+unset SYSROOT && $(MAKE) MEMO_TARGET=watchos-arm64 MEMO_CFVER=1400 rebuild-all
	+unset SYSROOT && $(MAKE) MEMO_TARGET=appletvos-arm64 MEMO_CFVER=1300 rebuild-all
	+unset SYSROOT && $(MAKE) MEMO_TARGET=iphoneos-arm MEMO_CFVER=1100 rebuild-all

include *.mk

package:: $(SUBPROJECTS:%=%-package)
bootstrap:: .SHELLFLAGS=-O extglob -c
bootstrap:: export BUILD_DIST=$(BUILD_STRAP)
bootstrap:: $(STRAPPROJECTS:%=%-package)
	rm -rf $(BUILD_STRAP)/strap
	rm -f $(BUILD_STAGE)/.fakeroot_bootstrap
	touch $(BUILD_STAGE)/.fakeroot_bootstrap
	mkdir -p $(BUILD_STRAP)/strap/Library/dpkg/info
	touch $(BUILD_STRAP)/strap/Library/dpkg/status
	cd $(BUILD_STRAP) && rm -f !(apt_*|base_*|bash_*|ca-certificates_*|coreutils_*|darwintools_*|debianutils_*|diffutils_*|diskdev-cmds_*|dpkg_*|essential_*|findutils_*|firmware-sbin_*|gpgv_*|grep_*|launchctl_*|libapt-pkg6.0_*|libcrypt2_*|libgcrypt20_*|libgpg-error0_*|libintl8_*|liblz4-1_*|liblzma5_*|libncursesw6_*|libpcre1_*|libreadline8_*|libssl1.1_*|libzstd1_*|ncurses-term_*|ncurses-bin_*|openssh_*|openssh-client_*|openssh-server_*|openssh-sftp-server_*|procursus-keyring_*|profile.d_*|sed_*|shell-cmds_*|snaputil_*|sudo_*|system-cmds_*|tar_*|uikittools_*|zsh_*).deb
	-for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		$(CP) $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | $(SED) '1 s/$$/./' | $(SED) 's/\/$$//' > $(BUILD_STRAP)/strap/Library/dpkg/info/$$PKGNAME.list; \
		$(CP) $(BUILD_INFO)/$$PKGNAME.{preinst,postinst,extrainst_,prerm,postrm} $(BUILD_STRAP)/strap/Library/dpkg/info; \
		cat $(BUILD_STRAP)/strap/DEBIAN/control >> $(BUILD_STRAP)/strap/Library/dpkg/status; \
		echo -e "Status: install ok installed\n" >> $(BUILD_STRAP)/strap/Library/dpkg/status; \
		rm -rf $(BUILD_STRAP)/strap/DEBIAN; \
	done
	$(RMDIR) --ignore-fail-on-non-empty $(BUILD_STRAP)/strap/{Applications,bin,dev,etc/{default,profile.d},Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},System/Library,System,tmp,usr/{bin,games,include,sbin,var,share/{dict,misc}},var/{backups,cache,db,lib/misc,local,lock,logs,mobile/{Library/Preferences,Library,Media},mobile,msgs,preferences,root/Media,root,run,spool,tmp,vm}}
	mkdir -p $(BUILD_STRAP)/strap/private
	rm -f $(BUILD_STRAP)/strap/{sbin/{fsck,fsck_apfs,fsck_exfat,fsck_hfs,fsck_msdos,launchd,mount,mount_apfs,newfs_apfs,newfs_hfs,pfctl},usr/sbin/{BTAvrcp,BTLEServer,BTMap,BTPbap,BlueTool,WirelessRadioManagerd,absd,addNetworkInterface,aslmanager,bluetoothd,cfprefsd,distnoted,filecoordinationd,ioreg,ipconfig,mDNSResponder,mDNSResponderHelper,mediaserverd,notifyd,nvram,pppd,racoon,rtadvd,scutil,spindump,syslogd,wifid}}
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
	rm -f $(BUILD_STRAP)/strap/sbin/umount
endif
	mv $(BUILD_STRAP)/strap/{etc,var} $(BUILD_STRAP)/strap/private
	mkdir -p $(BUILD_STRAP)/strap/private/var/log/dpkg
	if [ $(PLATFORM) = "appletvos" ]; then \
		mgr=nitotv;\
	else \
		mgr=cydia; \
	fi; \
	mkdir -p $(BUILD_STRAP)/strap/private/var/lib/$$mgr; \
	mkdir -p $(BUILD_STRAP)/strap/usr/libexec/$$mgr; \
	cd $(BUILD_STRAP)/strap/usr/libexec/$$mgr && ln -fs ../firmware.sh
	chmod 0775 $(BUILD_STRAP)/strap/Library
	mkdir -p $(BUILD_STRAP)/strap/private/etc/apt/preferences.d
	$(CP) $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/private/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/.procursus_strapped
	touch $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	echo -e "Types: deb\n\
URIs: https://apt.procurs.us/\n\
Suites: iphoneos-arm64/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
	$$FAKEROOT chown 0:80 $(BUILD_STRAP)/strap/Library; \
	$$FAKEROOT chown 0:3 $(BUILD_STRAP)/strap/private/var/empty; \
	$$FAKEROOT chown 0:1 $(BUILD_STRAP)/strap/private/var/run; \
	cd $(BUILD_STRAP)/strap && $$FAKEROOT $(TAR) -cf ../bootstrap.tar .
	@if [[ "$(SSH_STRAP)" = 1 ]]; then \
		BOOTSTRAP=bootstrap-ssh.tar.zst; \
	else \
		BOOTSTRAP=bootstrap.tar.zst; \
	fi; \
	zstd -qf -c19 --rm $(BUILD_STRAP)/bootstrap.tar > $(BUILD_STRAP)/$${BOOTSTRAP}; \
	rm -rf $(BUILD_STRAP)/{strap,*.deb}; \
	echo "********** Successfully built bootstrap with **********"; \
	echo "$(STRAPPROJECTS)"; \
	echo "$(BUILD_STRAP)/$${BOOTSTRAP}"

bootstrap-device: bootstrap
	@echo "********** Bootstrapping device. This may take a while! **********"
	$(BUILD_TOOLS)/bootstrap_device.sh

%-package: FAKEROOT=fakeroot -i $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) -s $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) --
%-package: .SHELLFLAGS=-O extglob -c
%-stage: %
	rm -f $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)
	touch $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)

REPROJ=$(shell echo $@ | cut -f2- -d"-")
REPROJ2=$(shell echo $(REPROJ) | $(SED) 's/-package//')
rebuild-%:
	@echo Rebuild $(REPROJ2)
	-if [ $(REPROJ) = "all" ] || [ $(REPROJ) = "package" ]; then \
		rm -rf $(BUILD_WORK) $(BUILD_STAGE); \
		git submodule foreach --recursive git clean -xfd; \
		git submodule foreach --recursive git reset --hard; \
		rm -f darwintools/.build_complete; \
		$(MAKE) -C darwintools clean; \
	fi
	-if [ -d $(BUILD_WORK)/$(REPROJ2) ]; then \
		rm -rf {$(BUILD_WORK),$(BUILD_STAGE)}/$(REPROJ2); \
	elif [ -d $(REPROJ2) ]; then \
		cd $(REPROJ2) && git clean -xfd && git reset; \
	fi
	rm -rf $(BUILD_WORK)/$(REPROJ2)*patches
	rm -rf $(BUILD_STAGE)/$(REPROJ2)
	+$(MAKE) $(REPROJ)

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)/{System/Library/Frameworks,usr/{include/{bsm,os,sys,IOKit,libkern,mach/machine},lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_DIST) $(BUILD_STRAP)

	git submodule update --init --recursive

	wget -q -nc -P $(BUILD_BASE)/usr/include \
		https://opensource.apple.com/source/xnu/xnu-6153.61.1/libsyscall/wrappers/spawn/spawn.h

	wget -q -nc -P $(BUILD_BASE)/usr/include/mach/machine \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/osfmk/mach/machine/thread_state.h

	wget -q -nc -P $(BUILD_BASE)/usr/include/bsm \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/bsm/audit_kevents.h

	@# Copy headers from MacOSX.sdk
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{arpa,net,xpc} $(BUILD_BASE)/usr/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/libkern/OSTypes.h $(BUILD_BASE)/usr/include/libkern
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,ptrace,kern*,random,vnode}.h $(BUILD_BASE)/usr/include/sys
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/usr/include/IOKit
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{ar,launch,libproc,tzfile}.h $(BUILD_BASE)/usr/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/usr/include/mach
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/usr/include/mach/machine
	$(CP) -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/usr/include/os
	-$(CP) -af $(BUILD_INFO)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/System/Library/Frameworks/IOKit.framework

	@# Patch headers from iPhoneOS.sdk
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)/usr/include/stdlib.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)/usr/include/time.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)/usr/include/unistd.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)/usr/include/mach/task.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)/usr/include/mach/mach_host.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)/usr/include/ucontext.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)/usr/include/signal.h

	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)

clean::
	rm -rf $(BUILD_WORK) $(BUILD_BASE) $(BUILD_STAGE)
	@# When using 'make clean' in submodules, there is still an issue with the subproject changing when committing. This fixes that.
	git submodule foreach --recursive git clean -xfd
	git submodule foreach --recursive git reset --hard
	rm -f darwintools/.build_complete
	-$(MAKE) -C darwintools clean

extreme-clean:: clean
	git clean -xfd && git reset

.PHONY: clean setup
