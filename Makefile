ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Procursus - sudo apt install make)
endif

ifeq ($(shell LANG=C /usr/bin/env bash --version | grep -iq 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

# Unset sysroot, we manage that ourselves.
SYSROOT :=

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
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM        := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),appletvos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for tvOS)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM        := AppleTVOS
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),watchos-arm64_32)
ifneq ($(MEMO_QUIET),1)
$(warning Building for WatchOS)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WatchOS.sdk
BARE_PLATFORM        := WatchOS
export WATCHOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),darwin-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS arm64e)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM        := MacOSX

else ifeq ($(MEMO_TARGET),darwin-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS arm64)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM        := MacOSX

else ifeq ($(MEMO_TARGET),darwin-amd64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS amd64)
endif # ($(MEMO_QUIET),1)
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
ON_DEVICE_SDK_PATH   := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM        := MacOSX

else
$(error Platform not supported)
endif

ifeq ($(UNAME),Linux)
ifneq ($(MEMO_QUIET),1)
$(warning Building on GNU Linux)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= $(HOME)/cctools/SDK/$(BARE_PLATFORM).sdk
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
LIBTOOL  := $(GNU_HOST_TRIPLE)-libtool

BUILD_CFLAGS   :=
BUILD_CPPFLAGS :=
BUILD_CXXFLAGS :=
BUILD_LDFLAGS  :=

else ifeq ($(UNAME),FreeBSD)
ifneq ($(MEMO_QUIET),1)
$(warning Building on FreeBSD)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= $(HOME)/cctools/SDK/$(BARE_PLATFORM).sdk
MACOSX_SYSROOT  ?= $(HOME)/cctools/SDK/MacOSX.sdk
CC      := $(GNU_HOST_TRIPLE)-clang
CXX     := $(GNU_HOST_TRIPLE)-clang++
CPP     := $(GNU_HOST_TRIPLE)-clang -E
AR      := $(GNU_HOST_TRIPLE)-ar
LD      := $(GNU_HOST_TRIPLE)-ld 
RANLIB  := $(GNU_HOST_TRIPLE)-ranlib   
STRIP   := $(GNU_HOST_TRIPLE)-strip
I_N_T   := $(GNU_HOST_TRIPLE)-install_name_tool
NM      := $(GNU_HOST_TRIPLE)-nm
LIPO    := $(GNU_HOST_TRIPLE)-lipo
OTOOL   := $(GNU_HOST_TRIPLE)-otool
LIBTOOL := $(GNU_HOST_TRIPLE)-libtool
PATH    := $(GNUBINDIR):$(PATH)

BUILD_CFLAGS   :=
BUILD_CPPFLAGS :=
BUILD_CXXFLAGS :=
BUILD_LDFLAGS  :=

else ifeq ($(UNAME),Darwin)
ifeq ($(shell sw_vers -productName),macOS)
ifneq ($(MEMO_QUIET),1)
$(warning Building on MacOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= $(shell xcrun --sdk $(PLATFORM) --show-sdk-path)
MACOSX_SYSROOT  ?= $(shell xcrun --show-sdk-path)
CC              := $(shell xcrun --sdk $(PLATFORM) --find cc)
CXX             := $(shell xcrun --sdk $(PLATFORM) --find c++)
CPP             := $(shell xcrun --sdk $(PLATFORM) --find cpp)
PATH            := /opt/procursus/bin:/opt/procursus/libexec/gnubin:/usr/bin:$(PATH)

BUILD_CFLAGS   := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
BUILD_CPPFLAGS := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
BUILD_CXXFLAGS := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
BUILD_LDFLAGS  := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)

else
ifneq ($(MEMO_QUIET),1)
$(warning Building on iOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= /usr/share/SDKs/$(BARE_PLATFORM).sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CC              := cc
CXX             := c++
CPP             := cc -E
PATH            := /usr/bin:$(PATH)

BUILD_CFLAGS   := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion) -isysroot /usr/share/SDKs/iPhoneOS.sdk
BUILD_CPPFLAGS := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion) -isysroot /usr/share/SDKs/iPhoneOS.sdk
BUILD_CXXFLAGS := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion) -isysroot /usr/share/SDKs/iPhoneOS.sdk
BUILD_LDFLAGS  := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion) -isysroot /usr/share/SDKs/iPhoneOS.sdk

endif
AR              := ar
LD              := ld
RANLIB          := ranlib
STRIP           := strip
NM              := nm
LIPO            := lipo
OTOOL           := otool
I_N_T           := install_name_tool
LIBTOOL         := libtool

else
$(error Please use Linux, MacOS or FreeBSD to build)
endif

CC_FOR_BUILD  := $(shell which cc) $(BUILD_CFLAGS)
CPP_FOR_BUILD := $(shell which cc) -E $(BUILD_CPPFLAGS)
CXX_FOR_BUILD := $(shell which c++) $(BUILD_CXXFLAGS)
export CC_FOR_BUILD CPP_FOR_BUILD CXX_FOR_BUILD

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


ifeq ($(DEBUG),1)
OPTIMIZATION_FLAGS := -g -O0
else
OPTIMIZATION_FLAGS := -Os
ifeq ($(UNAME),Darwin)
ifeq ($(shell sw_vers -productName),macOS)
OPTIMIZATION_FLAGS += -flto=thin
endif
endif
endif

CFLAGS              := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
CPPFLAGS            := -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -Wno-error-implicit-function-declaration
LDFLAGS             := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
#PKG_CONFIG_PATH     := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/pkgconfig:$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/pkgconfig
#PKG_CONFIG_LIBDIR   := $(PKG_CONFIG_PATH)
ACLOCAL_PATH        := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal

DEFAULT_CMAKE_FLAGS := \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CROSSCOMPILING=true \
	-DCMAKE_SYSTEM_NAME=Darwin \
	-DCMAKE_SYSTEM_PROCESSOR=$(shell echo $(GNU_HOST_TRIPLE) | cut -f1 -d-) \
	-DCMAKE_C_FLAGS="$(CFLAGS)" \
	-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
	-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
	-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
	-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
	-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	-DCMAKE_INSTALL_SYSCONFDIR=$(MEMO_PREFIX)/etc \
	-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
	-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)"

DEFAULT_CONFIGURE_FLAGS := \
	--build=$$($(BUILD_MISC)/config.guess) \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	--localstatedir=$(MEMO_PREFIX)/var \
	--sysconfdir=$(MEMO_PREFIX)/etc \
	--bindir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	--mandir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
	--disable-dependency-tracking

DEFAULT_PERL_MAKE_FLAGS := \
	INSTALLSITEARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	INSTALLARCHLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	INSTALLVENDORARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	INSTALLPRIVLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	INSTALLSITELIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	INSTALLVENDORLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	PERL_LIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	PERL_ARCHLIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	PERL_ARCHLIBDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	PERL_INC=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
	PERL_INCDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
	PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	INSTALLMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLSITEMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLVENDORMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	INSTALLSITEMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	INSTALLVENDORMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	PERL="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl" \
	CCFLAGS="$(CFLAGS)" \
	LDDLFLAGS="$(LDFLAGS) -shared"

DEFAULT_PERL_BUILD_FLAGS := \
	cc=$(CC) \
	ld=$(CC) \
	destdir=$(BUILD_STAGE)/libmodule-build-perl \
	install_base=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	install_path=lib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	install_path=arch=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
	install_path=bin=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	install_path=script=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	install_path=libdoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	install_path=bindoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	install_path=html=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/perl5

DEFAULT_GOLANG_FLAGS := \
	GOOS=$(shell echo $(RUST_TARGET) | cut -f3 -d-) \
	GOARCH=$(shell echo $(MEMO_TARGET) | cut -f2 -d-) \
	CGO_CFLAGS="$(CFLAGS)" \
	CGO_CXXFLAGS="$(CXXFLAGS)" \
	CGO_CPPFLAGS="$(CPPFLAGS)" \
	CGO_LDFLAGS="$(LDFLAGS)" \
	CGO_ENABLED=1 \
	CC="$(CC)" \
	CXX="$(CXX)" \
	CPP="$(CPP)"

export PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE MEMO_PREFIX MEMO_SUB_PREFIX MEMO_ALT_PREFIX
export CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T INSTALL
export BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS ACLOCAL_PATH #PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
export DEFAULT_CMAKE_FLAGS DEFAULT_CONFIGURE_FLAGS DEFAULT_PERL_MAKE_FLAGS DEFAULT_PERL_BUILD_FLAGS DEFAULT_GOLANG_FLAGS

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
ifeq ($(NO_PGP),1)
ifneq ($(MEMO_QUIET),1)
PGP_VERIFY  = echo "Skipping verification of $(1) because NO_PGP was set to 1."
else # ($(MEMO_QUIET),1)
PGP_VERIFY  = 
endif # ($(MEMO_QUIET),1)
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

DO_PATCH    = cd $(BUILD_PATCH)/$(1); \
	for PATCHFILE in *; do \
		if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done ]; then \
			patch -sN -d $(BUILD_WORK)/$(2) $(3) < $$PATCHFILE && \
			touch $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done; \
		fi; \
	done

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SIGN = 	for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			$(STRIP) -x $$file; \
			if [ $${file\#\#*.} = "dylib" ] || [ $${file\#\#*.} = "bundle" ] || [ $${file\#\#*.} = "so" ]; then \
				$(LDID) -S $$file; \
			else \
				$(LDID) -S$(BUILD_INFO)/$(2) $$file; \
			fi; \
		done; \
		find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete
else
SIGN = 	for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			$(STRIP) -x $$file; \
			codesign --remove $$file &> /dev/null; \
			codesign --sign $(CODESIGN_IDENTITY) --force --preserve-metadata=entitlements,requirements,flags,runtime $$file &> /dev/null; \
		done
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
		if [ ! $(MEMO_QUIET) == "1" ]; then \
		echo Setting $(1) owner to 0:0.; \
		fi; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/* &>/dev/null; \
	elif [ $(3) = "2" ]; then \
		if [ ! $(MEMO_QUIET) == "1" ]; then \
		echo $(1) owner set within individual makefile.; \
		fi; \
	fi; \
	if [ -d "$(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale" ] && [ ! "$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')" = "gettext-localizations" ]; then \
		rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/*/LC_TIME; \
		$(CP) -af $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/$(1)-locales; \
		rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale; \
	fi; \
	SIZE=$$(du -sk $(BUILD_DIST)/$(1) | cut -f 1); \
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
	$(CP) $(BUILD_INFO)/$(1).conffiles $(BUILD_DIST)/$(1)/DEBIAN/conffiles; \
	$(CP) $(BUILD_INFO)/$(1).conffiles.$(PLATFORM) $(BUILD_DIST)/$(1)/DEBIAN/conffiles; \
	$(SED) -i ':a; s/@$(2)@/$($(2))/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	for i in postinst preinst postrm prerm extrainst_ conffiles; do \
		$(SED) -i ':a; s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
		$(SED) -i ':a; s|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
		$(SED) -i ':a; s|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
		$(SED) -i ':a; s|@GNU_PREFIX@|$(GNU_PREFIX)|g; ta' $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
	done; \
	sed -i -e '$$a\' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	if [ -d "$(BUILD_DIST)/$(1)-locales" ]; then \
		$(call PACK_LOCALE,$(1)); \
	fi; \
	cd $(BUILD_DIST)/$(1) && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	if [ ! $(MEMO_QUIET) == "1" ]; then \
	echo "Installed-Size: $$SIZE"; \
	fi; \
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

GITHUB_ARCHIVE = -if [ $(5) ]; then \
					[ ! -f "$(BUILD_SOURCE)/$(5)-$(3).tar.gz" ] && \
						wget -q -nc -O$(BUILD_SOURCE)/$(5)-$(3).tar.gz \
							https://github.com/$(1)/$(2)/archive/$(4).tar.gz; \
				else \
					[ ! -f "$(BUILD_SOURCE)/$(2)-$(3).tar.gz" ] && \
						wget -q -nc -O$(BUILD_SOURCE)/$(2)-$(3).tar.gz \
							https://github.com/$(1)/$(2)/archive/$(4).tar.gz; \
				fi

GIT_CLONE = if [ ! -d "$(BUILD_WORK)/$(3)" ]; then \
				git clone -c advice.detachedHead=false --depth 1 --branch "$(2)" --recursive "$(1)" "$(BUILD_WORK)/$(3)"; \
			fi

###
#
# Fix this dep checking section dumbass
#
###

ifneq ($(call HAS_COMMAND,wget),1)
$(error Install wget)
endif

ifneq ($(call HAS_COMMAND,triehash),1)
$(error Install triehash)
endif

ifeq ($(call HAS_COMMAND,gmake),1)
# Fix this check.
endif

TAR  := tar # TODO: remove

ifneq ($(shell PATH=$(PATH) tar --version | grep -q GNU && echo 1),1)
$(error Install GNU tar)
endif

SED  := sed # TODO: remove

ifneq ($(shell PATH=$(PATH) sed --version | grep -q GNU && echo 1),1)
$(error Install GNU sed)
endif

ifeq ($(call HAS_COMMAND,ldid),1)
export LDID := ldid
else
$(error Install ldid)
endif

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
export GINSTALL := install # TODO: remove
export INSTALL  := $(shell PATH=$(PATH) which install) --strip-program=$(STRIP)
else
$(error Install GNU coreutils)
endif

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

ifeq ($(shell dpkg-deb --help | grep -qi "zstd" && echo 1),1)
DPKG_TYPE ?= zstd
else
DPKG_TYPE ?= gzip
endif
ifeq ($(call HAS_COMMAND,dpkg-deb),1)
DPKG_DEB := dpkg-deb -Z$(DPKG_TYPE)
else ifeq ($(call HAS_COMMAND,dm.pl),1)
DPKG_DEB := dm.pl -Z$(DPKG_TYPE)
else
$(error Install dpkg-deb)
endif

ifneq ($(call HAS_COMMAND,autopoint),1)
$(error Install autopoint)
endif

ifneq ($(shell tic -V | grep -q 'ncurses 6' && echo 1),1)
$(error Install ncurses 6)
endif

ifneq (,$(wildcard /opt/procursus/share/xml/docbook/stylesheet/docbook-xsl))
DOCBOOK_XSL := /opt/procursus/share/xml/docbook/stylesheet/docbook-xsl
export XML_CATALOG_FILES=/opt/procursus/etc/xml/catalog
else ifneq (,$(wildcard /usr/share/xml/docbook/stylesheet/docbook-xsl))
DOCBOOK_XSL := /usr/share/xml/docbook/stylesheet/docbook-xsl
export XML_CATALOG_FILES=/etc/xml/catalog
else ifneq (,$(wildcard /usr/local/share/xsl/docbook))
DOCBOOK_XSL := /usr/local/share/xsl/docbook
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
	@echo -e "\tMEMO_TARGET='$(MEMO_TARGET)' PLATFORM='$(PLATFORM)' MEMO_ARCH='$(MEMO_ARCH)' TARGET_SYSROOT='$(TARGET_SYSROOT)' MACOSX_SYSROOT='$(MACOSX_SYSROOT)' GNU_HOST_TRIPLE='$(GNU_HOST_TRIPLE)'"
	@echo -e "\tCC='$(CC)' CXX='$(CXX)' AR='$(AR)' LD='$(LD)' CPP='$(CPP)' RANLIB='$(RANLIB)' STRIP='$(STRIP)' NM='$(NM)' LIPO='$(LIPO)' OTOOL='$(OTOOL)' I_N_T='$(I_N_T)' EXTRA='$(EXTRA)' SED='$(SED)' LDID='$(LDID)' GINSTALL='$(GINSTALL)' LN='$(LN)' CP='$(CP)'"
	@echo -e "\tBUILD_ROOT='$(BUILD_ROOT)' BUILD_BASE='$(BUILD_BASE)' BUILD_INFO='$(BUILD_INFO)' BUILD_WORK='$(BUILD_WORK)' BUILD_STAGE='$(BUILD_STAGE)' BUILD_DIST='$(BUILD_DIST)' BUILD_STRAP='$(BUILD_STRAP)' BUILD_TOOLS='$(BUILD_TOOLS)'"
	@echo -e "\tDEB_ARCH='$(DEB_ARCH)' DEB_ORIGIN='$(DEB_ORIGIN)' DEB_MAINTAINER='$(DEB_MAINTAINER)'"
	@echo -e "\tCFLAGS='$(CFLAGS)'"
	@echo -e "\tCXXFLAGS='$(CXXFLAGS)'"
	@echo -e "\tCPPFLAGS='$(CPPFLAGS)'"
	@echo -e "\tLDFLAGS='$(LDFLAGS)'"
#	@echo -e "\tPKG_CONFIG_PATH='$(PKG_CONFIG_PATH)'"
	@echo -e "\texport MEMO_TARGET PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE"
	@echo -e "\texport CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA SED LDID GINSTALL LN CP"
	@echo -e "\texport BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS"
	@echo -e "\texport DEB_ARCH DEB_ORIGIN DEB_MAINTAINER"
	@echo -e "\texport CFLAGS CXXFLAGS CPPFLAGS LDFLAGS"
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
	cd $(BUILD_STRAP) && rm -f !(apt_*|base_*|bash_*|ca-certificates_*|coreutils_*|darwintools_*|dash_*|debianutils_*|diffutils_*|diskdev-cmds_*|dpkg_*|essential_*|file-cmds_*|findutils_*|firmware-sbin_*|gpgv_*|grep_*|launchctl_*|libapt-pkg6.0_*|libassuan0_*|libcrypt2_*|libedit0_*|libffi7_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|libiosexec1_*|liblz4-1_*|liblzma5_*|libmd0_*|libncursesw6_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libpam-modules_*|libpam2_*|libpcre1_*|libreadline8_*|libssl1.1_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|ncurses-bin_*|ncurses-term_*|openssh_*|openssh-client_*|openssh-server_*|openssh-sftp-server_*|procursus-keyring_*|profile.d_*|sed_*|shell-cmds_*|snaputil_*|sudo_*|system-cmds_*|tar_*|uikittools_*|zsh_*).deb
else # $(MEMO_TARGET),darwin-*
	cd $(BUILD_STRAP) && rm -f !(apt_*|ca-certificates_*|coreutils_*|darwintools_*|dpkg_*|gpgv_*|libapt-pkg6.0_*|libassuan0_*|libffi7_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|liblz4-1_*|liblzma5_*|libmd0_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|procursus-keyring_*|tar_*).deb
endif # $(MEMO_TARGET),darwin-*
	-for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		$(CP) $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | $(SED) '1 s/$$/./' | $(SED) 's/\/$$//' > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.list; \
		for script in preinst postinst extrainst_ prerm postrm; do \
			$(CP) $(BUILD_STRAP)/strap/DEBIAN/$$script $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.$$script; \
		done; \
		cat $(BUILD_STRAP)/strap/DEBIAN/control >> $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/status; \
		echo -e "Status: install ok installed\n" >> $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/status; \
		rm -rf $(BUILD_STRAP)/strap/DEBIAN; \
	done
ifeq ($(MEMO_PREFIX),)
	rmdir --ignore-fail-on-non-empty $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/{Applications,bin,dev,etc/{default,profile.d},Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},System/Library,System,tmp,$(MEMO_SUB_PREFIX)/{bin,games,include,sbin,share/{dict,misc}},var/{backups,cache,db,lib/misc,$(MEMO_ALT_PREFIX),lock,logs,mobile/{Library/Preferences,Library,Media},mobile,msgs,preferences,root/Media,root,run,spool,tmp,vm}}
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
	cp $(BUILD_MISC)/prep_bootstrap.sh $(BUILD_STRAP)/strap
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

%-deps: %
	@${BUILD_TOOLS}/find_deps.sh $(BUILD_STAGE)/$^

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os,sys,IOKit,libkern,mach/machine},lib/pkgconfig,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		https://opensource.apple.com/source/xnu/xnu-6153.61.1/libsyscall/wrappers/spawn/spawn.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/bootstrap_priv.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/vproc_priv.h

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/osfmk/mach/machine/thread_state.h

	wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm \
		https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/bsm/audit_kevents.h

	cp -a $(BUILD_MISC)/zlib.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

ifeq ($(UNAME),FreeBSD)
	@# FreeBSD does not have stdbool.h and stdarg.h
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool.h,stdarg.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@# Copy headers from MacOSX.sdk
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,net,xpc,netinet,servers} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/libkern/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,ptrace,kern*,random,reboot,user,vnode}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,libproc,NSSystemDirectories,tzfile,vproc}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	$(CP) -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	$(CP) -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	$(CP) -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
	-$(CP) -af $(BUILD_INFO)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework

	mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreAudio.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio

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

ifneq ($(MEMO_QUIET),1)
	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)
endif # ($(MEMO_QUIET),1)

clean::
	rm -rf $(BUILD_WORK) $(BUILD_BASE) $(BUILD_STAGE)

extreme-clean:: clean
	git clean -xfd && git reset

.PHONY: clean setup
