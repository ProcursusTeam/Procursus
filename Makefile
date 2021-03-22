ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Homebrew - brew install make)
endif

ifeq ($(shell /usr/bin/env bash --version | grep -iq 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

UNAME           := $(shell uname -s)
SUBPROJECTS     += $(STRAPPROJECTS)

ifneq ($(shell umask),0022)
$(error Please run `umask 022` before running this)
endif

MEMO_TARGET          ?= darwin-arm64
MEMO_CFVER           ?= 1700
# iOS 13.0 == 1665.15.
CFVER_WHOLE          := $(shell echo $(MEMO_CFVER) | cut -d. -f1)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1100 ] && [ "$(CFVER_WHOLE)" -lt 1200 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 8.0
APPLETVOS_DEPLOYMENT_TARGET := XXX
WATCHOS_DEPLOYMENT_TARGET   := 1.0
MACOSX_DEPLOYMENT_TARGET    := 10.10
override MEMO_CFVER         := 1100
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1200 ] && [ "$(CFVER_WHOLE)" -lt 1300 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 9.0
APPLETVOS_DEPLOYMENT_TARGET := 9.0
WATCHOS_DEPLOYMENT_TARGET   := 2.0
MACOSX_DEPLOYMENT_TARGET    := 10.11
override MEMO_CFVER         := 1200
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1300 ] && [ "$(CFVER_WHOLE)" -lt 1400 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 10.0
APPLETVOS_DEPLOYMENT_TARGET := 10.0
WATCHOS_DEPLOYMENT_TARGET   := 3.0
MACOSX_DEPLOYMENT_TARGET    := 10.12
override MEMO_CFVER         := 1300
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 11.0
APPLETVOS_DEPLOYMENT_TARGET := 11.0
WATCHOS_DEPLOYMENT_TARGET   := 4.0
MACOSX_DEPLOYMENT_TARGET    := 10.13
override MEMO_CFVER         := 1400
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1500 ] && [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 12.0
APPLETVOS_DEPLOYMENT_TARGET := 12.0
WATCHOS_DEPLOYMENT_TARGET   := 5.0
MACOSX_DEPLOYMENT_TARGET    := 10.14
override MEMO_CFVER         := 1500
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 13.0
APPLETVOS_DEPLOYMENT_TARGET := 13.0
WATCHOS_DEPLOYMENT_TARGET   := 6.0
MACOSX_DEPLOYMENT_TARGET    := 10.15
override MEMO_CFVER         := 1600
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 14.0
APPLETVOS_DEPLOYMENT_TARGET := 14.0
WATCHOS_DEPLOYMENT_TARGET   := 7.0
MACOSX_DEPLOYMENT_TARGET    := 11.0
MACOSX_SUITE_NAME           := big_sur
override MEMO_CFVER         := 1700
else
$(error Unsupported CoreFoundation version)
endif

export MACOSX_DEPLOYMENT_TARGET

ifeq ($(MEMO_TARGET),iphoneos-arm64)
$(warning Building for iOS)
MEMO_ARCH            := arm64
PLATFORM             := iphoneos
DEB_ARCH             := iphoneos-arm
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-ios
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),appletvos-arm64)
$(warning Building for tvOS)
MEMO_ARCH            := arm64
PLATFORM             := appletvos
DEB_ARCH             := appletvos-arm64
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-tvos
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),watchos-arm64_32)
$(warning Building for WatchOS)
MEMO_ARCH            := arm64_32
PLATFORM             := watchos
DEB_ARCH             := watchos-arm64_32
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-watchos
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
export WATCHOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),darwin-arm64e)
$(warning Building for macOS arm64e)
MEMO_ARCH            := arm64e
PLATFORM             := macosx
DEB_ARCH             := darwin-arm64e
GNU_HOST_TRIPLE      := aarch64-apple-darwin
RUST_TARGET          := $(GNU_HOST_TRIPLE)
PLATFORM_VERSION_MIN := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?= /opt/procursus
MEMO_SUB_PREFIX      ?=
MEMO_ALT_PREFIX      ?=
GNU_PREFIX           := g

else ifeq ($(MEMO_TARGET),darwin-arm64)
$(warning Building for macOS arm64)
MEMO_ARCH            := arm64
PLATFORM             := macosx
DEB_ARCH             := darwin-arm64
GNU_HOST_TRIPLE      := aarch64-apple-darwin
RUST_TARGET          := $(GNU_HOST_TRIPLE)
PLATFORM_VERSION_MIN := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?= /opt/procursus
MEMO_SUB_PREFIX      ?=
MEMO_ALT_PREFIX      ?=
GNU_PREFIX           := g

else ifeq ($(MEMO_TARGET),darwin-amd64)
$(warning Building for macOS amd64)
MEMO_ARCH            := x86_64
PLATFORM             := macosx
DEB_ARCH             := darwin-amd64
GNU_HOST_TRIPLE      := x86_64-apple-darwin
RUST_TARGET          := $(GNU_HOST_TRIPLE)
PLATFORM_VERSION_MIN := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?= /opt/procursus
MEMO_SUB_PREFIX      ?=
MEMO_ALT_PREFIX      ?=
GNU_PREFIX           := g

else
$(error Platform not supported)
endif

ifeq ($(UNAME),Linux)
$(warning Building on Linux)
TARGET_SYSROOT  ?= $(HOME)/cctools/SDK/iPhoneOS13.2.sdk
MACOSX_SYSROOT  ?= $(HOME)/cctools/SDK/MacOSX.sdk

CC       := $(GNU_HOST_TRIPLE)-clang
CXX      := $(GNU_HOST_TRIPLE)-clang++
CPP      := $(GNU_HOST_TRIPLE)-clang -E
AR       := $(GNU_HOST_TRIPLE)-ar
LD       := $(GNU_HOST_TRIPLE)-ld
RANLIB   := $(GNU_HOST_TRIPLE)-ranlib
STRIP    := $(GNU_HOST_TRIPLE)-strip
I_N_T    := $(GNU_HOST_TRIPLE)-install_name_tool
NM       := $(GNU_HOST_TRIPLE)-nm
LIPO     := $(GNU_HOST_TRIPLE)-lipo
OTOOL    := $(GNU_HOST_TRIPLE)-otool
EXTRA    := INSTALL="/usr/bin/install -c --strip-program=$(STRIP)"
LIBTOOL  := $(GNU_HOST_TRIPLE)-libtool

else ifeq ($(UNAME),Darwin)
ifeq ($(filter $(shell uname -m | cut -c -4), iPad iPho),)
$(warning Building on MacOS)
TARGET_SYSROOT  ?= $(shell xcrun --sdk $(PLATFORM) --show-sdk-path)
MACOSX_SYSROOT  ?= $(shell xcrun --show-sdk-path)
CC              := cc
CXX             := c++
CPP             := cc -E
PATH            := /opt/procursus/bin:/opt/procursus/libexec/gnubin:/usr/bin:$(PATH)

else
$(warning Building on iOS)
TARGET_SYSROOT  ?= /usr/share/SDKs/iPhoneOS.sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CC              := clang
CXX             := clang++
CPP             := clang -E
PATH            := /usr/bin:$(PATH)

endif
AR              := ar
LD              := ld
RANLIB          := ranlib
STRIP           := strip
NM              := nm
LIPO            := lipo
OTOOL           := otool
I_N_T           := install_name_tool
EXTRA           :=
LIBTOOL         := libtool

else
$(error Please use Linux or MacOS to build)
endif

DEB_MAINTAINER    ?= Hayden Seay <me@diatr.us>
CODESIGN_IDENTITY ?= -

# Root
BUILD_ROOT     ?= $(PWD)
# Downloaded source files
BUILD_SOURCE   := $(BUILD_ROOT)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     := $(BUILD_ROOT)/build_base/$(MEMO_TARGET)/$(MEMO_CFVER)
# Dpkg info storage area
BUILD_INFO     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_info
# Miscellaneous Procursus files
BUILD_MISC     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_misc
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

CFLAGS              := -O2 -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
CPPFLAGS            := -O2 -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -Wno-error-implicit-function-declaration
LDFLAGS             := -O2 -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
PKG_CONFIG_PATH     := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/pkgconfig
PKG_CONFIG_LIBDIR   := $(PKG_CONFIG_PATH)
ACLOCAL_PATH        := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal

export PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE MEMO_PREFIX MEMO_SUB_PREFIX MEMO_ALT_PREFIX CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA SED
export BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG_PATH PKG_CONFIG_LIBDIR ACLOCAL_PATH

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
	find $(BUILD_BASE)$(MEMO_PREFIX) -name "*.la" -type f -delete

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

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SIGN = find $(BUILD_DIST)/$(1) -type f -exec $(LDID) -S$(BUILD_INFO)/$(2) {} \; &> /dev/null; \
	find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete
else
SIGN = find $(BUILD_DIST)/$(1) -type f -exec codesign --remove {} \; &> /dev/null; \
	find $(BUILD_DIST)/$(1) -type f -exec codesign --sign $(CODESIGN_IDENTITY) --force --preserve-metadata=entitlements,requirements,flags,runtime {} \; &> /dev/null
endif

###
#
# TODO: Please cleanup the PACK function, it's so horrible.
#
###

PACK = -if [ -z $(4) ]; then \
		find $(BUILD_DIST)/$(1) -name '*.la' -type f -delete; \
	fi; \
	rm -f $(BUILD_DIST)/$(1)/.build_complete; \
	rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{info,doc}; \
	find $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -exec zstd -19 --rm '{}' \; 2> /dev/null; \
	if [ -z $(3) ]; then \
		echo Setting $(1) owner to 0:0.; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/* &>/dev/null; \
	elif [ $(3) = "2" ]; then \
		echo $(1) owner set within individual makefile.; \
	fi; \
	if [ -d "$(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale" ] && [ ! "$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')" = "gettext-localizations" ]; then \
		rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/*/LC_TIME; \
		$(CP) -af $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/$(1)-locales; \
		rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale; \
	fi; \
	SIZE=$$(du -s $(BUILD_DIST)/$(1) | cut -f 1); \
	mkdir -p $(BUILD_DIST)/$(1)/DEBIAN; \
	$(CP) $(BUILD_INFO)/$(1).control $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(CP) $(BUILD_INFO)/$(1).control.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(CP) $(BUILD_INFO)/$(1).postinst $(BUILD_DIST)/$(1)/DEBIAN/postinst; \
	$(CP) $(BUILD_INFO)/$(1).postinst.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/postinst; \
	$(CP) $(BUILD_INFO)/$(1).preinst $(BUILD_DIST)/$(1)/DEBIAN/preinst; \
	$(CP) $(BUILD_INFO)/$(1).preinst.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/preinst; \
	$(CP) $(BUILD_INFO)/$(1).postrm $(BUILD_DIST)/$(1)/DEBIAN/postrm; \
	$(CP) $(BUILD_INFO)/$(1).postrm.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/postrm; \
	$(CP) $(BUILD_INFO)/$(1).prerm $(BUILD_DIST)/$(1)/DEBIAN/prerm; \
	$(CP) $(BUILD_INFO)/$(1).prerm.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/prerm; \
	$(CP) $(BUILD_INFO)/$(1).extrainst_ $(BUILD_DIST)/$(1)/DEBIAN/extrainst_; \
	$(CP) $(BUILD_INFO)/$(1).extrainst_.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/extrainst_; \
	$(SED) -i ':a; s/@$(2)@/$($(2))/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	for i in postinst preinst postrm prerm extrainst_; do \
		$(SED) -i ':a; s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
		$(SED) -i ':a; s|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
		$(SED) -i ':a; s|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
	done; \
	if [ -d "$(BUILD_DIST)/$(1)-locales" ]; then \
		$(call PACK_LOCALE,$(1)); \
	fi; \
	cd $(BUILD_DIST)/$(1) && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	echo "Installed-Size: $$SIZE"; \
	echo "Installed-Size: $$SIZE" >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
	find $(BUILD_DIST)/$(1) -name '.DS_Store' -type f -delete; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/$$(grep Package: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ')_$($(2))_$$(grep Architecture: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ').deb

PACK_LOCALE = mkdir -p $(BUILD_DIST)/$(1)-locale/{DEBIAN,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share}; \
	$(CP) -af $(BUILD_DIST)/$(1)-locales $(BUILD_DIST)/$(1)-locale/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale; \
	rm -rf $(BUILD_DIST)/$(1)-locales; \
	rm -f $(BUILD_DIST)/$(1)-locale/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/locale.alias; \
	LSIZE=$$(du -s $(BUILD_DIST)/$(1)-locale | cut -f 1); \
	$(CP) $(BUILD_DIST)/$(1)/DEBIAN/control $(BUILD_DIST)/$(1)-locale/DEBIAN; \
	VERSION=$$(grep Version: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d " "); \
	if [[ "$(MEMO_TARGET)" == *"darwin"* ]]; then \
		$(SED) -i "s/^Depends:.*/Depends: $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d " ") (= $$VERSION)/" $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	else \
		$(SED) -i "s/^Depends:.*/Depends: $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d " ") (= $$VERSION), gettext-localizations/" $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	fi; \
	$(SED) -i 's/^Package:.*/Package: $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d " ")-locale/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Priority:.*/Priority: optional/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Section:.*/Section: Localizations/' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i 's/^Description:.*/Description: Locale files for $(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')./' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(SED) -i -e '/^Name:/d' -e '/^Provides:/d' -e '/^Replaces:/d' -e '/^Conflicts:/d' -e '/^Tag:/d' -e '/^Essential:/d' $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	echo "Installed-Size: $$LSIZE" >> $(BUILD_DIST)/$(1)-locale/DEBIAN/control; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1)-locale $(BUILD_DIST)/$$(grep Package: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ')-locale_$${VERSION}_$$(grep Architecture: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ').deb; \
	rm -rf $(BUILD_DIST)/$(1)-locale

###
#
# Fix this dep checking section dumbass
#
###

ifneq ($(call HAS_COMMAND,wget),1)
$(error Install wget)
endif

ifeq ($(call HAS_COMMAND,gmake),1)
# Fix this check.
endif

TAR  := tar

ifneq ($(shell PATH=$(PATH) tar --version | grep -q GNU && echo 1),1)
$(error Install GNU tar)
endif

SED  := sed

ifneq ($(shell PATH=$(PATH) sed --version | grep -q GNU && echo 1),1)
$(error Install GNU sed)
endif

ifeq ($(call HAS_COMMAND,ldid2),1)
LDID := ldid2
else ifeq ($(call HAS_COMMAND,ldid),1)
$(warning Using ldid. Abort now and install ldid2 if this ldid does not support SHA256)
LDID := ldid
else
$(error Install ldid2)
endif
export LDID

ifeq ($(call HAS_COMMAND,libtoolize),1)
LIBTOOLIZE := libtoolize
else ifeq ($(call HAS_COMMAND,glibtoolize),1)
LIBTOOLIZE := glibtoolize
else
#$(error Install libtool)
endif

ifneq ($(call HAS_COMMAND,xz),1)
$(error Install xz-utils)
endif

ifneq ($(call HAS_COMMAND,gpg),1)
$(error Install GnuPG gpg)
endif

ifneq ($(call HAS_COMMAND,dirmngr),1)
$(error Install GnuPG dirmngr)
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

ifneq ($(call HAS_COMMAND,autom4te),1)
$(error Install autoconf)
endif

ifneq ($(call HAS_COMMAND,m4),1)
$(error Install m4)
endif

ifneq ($(shell PATH=$(PATH) groff --version | grep -q 'version 1.2' && echo 1),1)
$(error Install newer groff)
endif

ifneq ($(shell PATH=$(PATH) patch --version | grep -q 'GNU patch' && echo 1),1)
$(error Install GNU patch)
endif

ifneq ($(shell PATH=$(PATH) find --version | grep -q 'GNU find' && echo 1),1)
$(error Install GNU findutils)
endif

ifneq ($(shell PATH=$(PATH) rmdir --version | grep -q 'GNU coreutils' && echo 1),1)
$(error Install GNU coreutils)
endif

ifeq ($(shell PATH=$(PATH) install --version | grep -q 'GNU coreutils' && echo 1),1)
GINSTALL := install
else
$(error Install GNU coreutils)
endif
export GINSTALL

ifeq ($(shell PATH=$(PATH) wc --version | grep -q 'GNU coreutils' && echo 1),1)
WC := wc
else
$(error Install GNU coreutils)
endif

ifeq ($(shell PATH=$(PATH) cp --version | grep -q 'GNU coreutils' && echo 1),1)
CP := cp
else
$(error Install GNU coreutils)
endif
export CP

ifeq ($(shell PATH=$(PATH) ln --version | grep -q 'GNU coreutils' && echo 1),1)
LN := ln
else
$(error Install GNU coreutils)
endif
export LN

ifneq ($(call HAS_COMMAND,fakeroot),1)
$(error Install fakeroot)
endif

ifneq ($(call HAS_COMMAND,zstd),1)
$(error Install zstd)
endif

DPKG_TYPE ?= zstd
ifeq ($(call HAS_COMMAND,dpkg-deb),1)
DPKG_DEB := dpkg-deb -Z$(DPKG_TYPE) 
else ifeq ($(call HAS_COMMAND,dm.pl),1)
DPKG_DEB := dm.pl -Z$(DPKG_TYPE) 
else
$(error Install dpkg-deb)
endif

ifneq ($(call HAS_COMMAND,autopoint),1)
$(error Install gettext)
endif

ifneq ($(shell tic -V | grep -q 'ncurses 6' && echo 1),1)
$(error Install ncurses 6)
endif

ifneq ($(LEAVE_ME_ALONE),1)

ifneq (,$(wildcard $(shell brew --prefix)/opt/docbook-xsl/docbook-xsl))
DOCBOOK_XSL := $(shell brew --prefix)/opt/docbook-xsl/docbook-xsl
export XML_CATALOG_FILES=$(shell brew --prefix)/etc/xml/catalog
else ifneq (,$(wildcard /usr/share/xml/docbook/stylesheet/docbook-xsl))
DOCBOOK_XSL := /usr/share/xml/docbook/stylesheet/docbook-xsl
else ifneq (,$(wildcard /usr/share/xsl/docbook))
DOCBOOK_XSL := /usr/share/xsl/docbook
else ifneq (,$(wildcard /usr/share/xml/docbook/xsl-stylesheets-1.79.2))
DOCBOOK_XSL := /usr/share/xml/docbook/xsl-stylesheets-1.79.2
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

env:
	@echo -e "proenv() {"
	@echo -e "\tPLATFORM='$(PLATFORM)' MEMO_ARCH='$(MEMO_ARCH)' TARGET_SYSROOT='$(TARGET_SYSROOT)' MACOSX_SYSROOT='$(MACOSX_SYSROOT)' GNU_HOST_TRIPLE='$(GNU_HOST_TRIPLE)'"
	@echo -e "\tCC='$(CC)' CXX='$(CXX)' AR='$(AR)' LD='$(LD)' CPP='$(CPP)' RANLIB='$(RANLIB)' STRIP='$(STRIP)' NM='$(NM)' LIPO='$(LIPO)' OTOOL='$(OTOOL)' I_N_T='$(I_N_T)' EXTRA='$(EXTRA)' SED='$(SED)' LDID='$(LDID)' GINSTALL='$(GINSTALL)' LN='$(LN)' CP='$(CP)'"
	@echo -e "\tBUILD_ROOT='$(BUILD_ROOT)' BUILD_BASE='$(BUILD_BASE)' BUILD_INFO='$(BUILD_INFO)' BUILD_WORK='$(BUILD_WORK)' BUILD_STAGE='$(BUILD_STAGE)' BUILD_DIST='$(BUILD_DIST)' BUILD_STRAP='$(BUILD_STRAP)' BUILD_TOOLS='$(BUILD_TOOLS)'"
	@echo -e "\tDEB_ARCH='$(DEB_ARCH)' DEB_ORIGIN='$(DEB_ORIGIN)' DEB_MAINTAINER='$(DEB_MAINTAINER)'"
	@echo -e "\tCFLAGS='$(CFLAGS)'"
	@echo -e "\tCXXFLAGS='$(CXXFLAGS)'"
	@echo -e "\tCPPFLAGS='$(CPPFLAGS)'"
	@echo -e "\tLDFLAGS='$(LDFLAGS)'"
	@echo -e "\tPKG_CONFIG_PATH='$(PKG_CONFIG_PATH)'"
	@echo -e "\texport PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE"
	@echo -e "\texport CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA SED LDID GINSTALL LN CP"
	@echo -e "\texport BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS"
	@echo -e "\texport DEB_ARCH DEB_ORIGIN DEB_MAINTAINER"
	@echo -e "\texport CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG_PATH"
	@echo -e "}"

viewenv:
	env

include *.mk

package:: $(SUBPROJECTS:%=%-package)

strapprojects:: export BUILD_DIST=$(BUILD_STRAP)
strapprojects:: $(STRAPPROJECTS:%=%-package)
bootstrap:: .SHELLFLAGS=-O extglob -c
bootstrap:: strapprojects
	mkdir -p $(BUILD_DIST)
	cp -a $(BUILD_STRAP)/*.deb $(BUILD_DIST)
	rm -rf $(BUILD_STRAP)/strap
	rm -f $(BUILD_STAGE)/.fakeroot_bootstrap
	touch $(BUILD_STAGE)/.fakeroot_bootstrap
	mkdir -p $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/status
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_STRAP) && rm -f !(apt_*|base_*|bash_*|ca-certificates_*|coreutils_*|darwintools_*|debianutils_*|diffutils_*|diskdev-cmds_*|dpkg_*|essential_*|file-cmds_*|findutils_*|firmware-sbin_*|gpgv_*|grep_*|launchctl_*|libapt-pkg6.0_*|libcrypt2_*|libgcrypt20_*|libgpg-error0_*|libintl8_*|liblz4-1_*|liblzma5_*|libncursesw6_*|libpcre1_*|libreadline8_*|libssl1.1_*|libxxhash0_*|libzstd1_*|ncurses-bin_*|ncurses-term_*|openssh_*|openssh-client_*|openssh-server_*|openssh-sftp-server_*|procursus-keyring_*|profile.d_*|sed_*|shell-cmds_*|snaputil_*|sudo_*|system-cmds_*|tar_*|uikittools_*|zsh_*).deb
else # $(MEMO_TARGET),darwin-*
	cd $(BUILD_STRAP) && rm -f !(apt_*|coreutils_*|darwintools_*|dpkg_*|gpgv_*|libapt-pkg6.0_*|libgcrypt20_*|libgpg-error0_*|libintl8_*|liblz4-1_*|liblzma5_*|libxxhash0_*|libzstd1_*|procursus-keyring_*|tar_*).deb
endif # $(MEMO_TARGET),darwin-*
	-for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		$(CP) $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | $(SED) '1 s/$$/./' | $(SED) 's/\/$$//' > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.list; \
		$(CP) $(BUILD_INFO)/$$PKGNAME.{preinst,postinst,extrainst_,prerm,postrm} $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info; \
		cat $(BUILD_STRAP)/strap/DEBIAN/control >> $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/status; \
		echo -e "Status: install ok installed\n" >> $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/status; \
		rm -rf $(BUILD_STRAP)/strap/DEBIAN; \
	done
ifeq ($(MEMO_PREFIX),)
	rmdir --ignore-fail-on-non-empty $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/{Applications,bin,dev,etc/{default,profile.d},Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},System/Library,System,tmp,$(MEMO_SUB_PREFIX)/{bin,games,include,sbin,var,share/{dict,misc}},var/{backups,cache,db,lib/misc,$(MEMO_ALT_PREFIX),lock,logs,mobile/{Library/Preferences,Library,Media},mobile,msgs,preferences,root/Media,root,run,spool,tmp,vm}}
	mkdir -p $(BUILD_STRAP)/strap/private
	rm -f $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/{sbin/{fsck,fsck_apfs,fsck_exfat,fsck_hfs,fsck_msdos,launchd,mount,mount_apfs,newfs_apfs,newfs_hfs,pfctl},$(MEMO_SUB_PREFIX)/sbin/{BTAvrcp,BTLEServer,BTMap,BTPbap,BlueTool,WirelessRadioManagerd,absd,addNetworkInterface,aslmanager,bluetoothd,cfprefsd,distnoted,filecoordinationd,ioreg,ipconfig,mDNSResponder,mDNSResponderHelper,mediaserverd,notifyd,nvram,pppd,racoon,rtadvd,scutil,spindump,syslogd,wifid}}
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
	rm -f $(BUILD_STRAP)/strap/sbin/umount
endif # $(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1
	mv $(BUILD_STRAP)/strap/{etc,var} $(BUILD_STRAP)/strap/private
	mkdir -p $(BUILD_STRAP)/strap/private/var/log/dpkg
	if [ $(PLATFORM) = "appletvos" ]; then \
		mgr=nitotv;\
	else \
		mgr=cydia; \
	fi; \
	mkdir -p $(BUILD_STRAP)/strap/private/var/lib/$$mgr; \
	mkdir -p $(BUILD_STRAP)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/$$mgr; \
	cd $(BUILD_STRAP)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/$$mgr && ln -fs ../firmware.sh
	chmod 0775 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library
	mkdir -p $(BUILD_STRAP)/strap/private/etc/apt/preferences.d
	$(CP) $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/private/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/.procursus_strapped
	touch $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	echo -e "Types: deb\n\
URIs: https://apt.procurs.us/\n\
Suites: $(MEMO_TARGET)/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
	$$FAKEROOT chown 0:80 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library; \
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
else # ($(MEMO_PREFIX),)
	chmod 0775 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library
	mkdir -p $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/preferences.d
	$(CP) $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/.procursus_strapped
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	echo -e "Types: deb\n\
URIs: https://apt.procurs.us/\n\
Suites: $(MACOSX_SUITE_NAME)\n\
Components: main\n" > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
else
	echo -e "Types: deb\n\
URIs: https://apt.procurs.us/\n\
Suites: $(MEMO_TARGET)/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
endif
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
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
endif # ($(MEMO_PREFIX),)

bootstrap-device: bootstrap
	@echo "********** Bootstrapping device. This may take a while! **********"
	$(BUILD_TOOLS)/bootstrap_device.sh

%-package: FAKEROOT=fakeroot -i $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) -s $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) --
%-package: .SHELLFLAGS=-O extglob -c
%-stage: %
	rm -f $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)
	touch $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)
	mkdir -p $(BUILD_DIST)

REPROJ=$(shell echo $@ | cut -f2- -d"-")
REPROJ2=$(shell echo $(REPROJ) | $(SED) 's/-package//' | $(SED) 's/-setup//')
rebuild-%:
	@echo Rebuild $(REPROJ2)
	-if [ $(REPROJ) = "all" ] || [ $(REPROJ) = "package" ]; then \
		rm -rf $(BUILD_WORK) $(BUILD_STAGE); \
	fi
	rm -rf {$(BUILD_WORK),$(BUILD_STAGE)}/$(REPROJ2)
	rm -rf $(BUILD_WORK)/$(REPROJ2)*patches
	rm -rf $(BUILD_STAGE)/$(REPROJ2)
	+$(MAKE) $(REPROJ)

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os,sys,IOKit,libkern,mach/machine},lib,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		https://opensource.apple.com/source/xnu/xnu-6153.61.1/libsyscall/wrappers/spawn/spawn.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/bootstrap_priv.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/vproc_priv.h

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/osfmk/mach/machine/thread_state.h

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/bsm/audit_kevents.h

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@# Copy headers from MacOSX.sdk
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{arpa,net,xpc,netinet} $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/libkern/OSTypes.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,ptrace,kern*,random,vnode}.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{ar,launch,libcharset,localcharset,libproc,tzfile}.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	$(CP) -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	$(CP) -af $(BUILD_INFO)/availability.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
	-$(CP) -af $(BUILD_INFO)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework

	@# Patch headers from iPhoneOS.sdk
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/time.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/task.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/mach_host.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ucontext.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/signal.h
	$(SED) -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pthread.h
endif

	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)

clean::
	rm -rf $(BUILD_WORK) $(BUILD_BASE) $(BUILD_STAGE)

extreme-clean:: clean
	git clean -xfd && git reset

.PHONY: clean setup
