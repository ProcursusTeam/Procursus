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
AUDIOOS_DEPLOYMENT_TARGET   := XXX
BRIDGEOS_DEPLOYMENT_TARGET  := XXX
WATCHOS_DEPLOYMENT_TARGET   := 1.0
MACOSX_DEPLOYMENT_TARGET    := 10.10
DARWIN_DEPLOYMENT_VERSION   := 14
override MEMO_CFVER         := 1100
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1200 ] && [ "$(CFVER_WHOLE)" -lt 1300 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 9.0
APPLETVOS_DEPLOYMENT_TARGET := 9.0
AUDIOOS_DEPLOYMENT_TARGET   := XXX
BRIDGEOS_DEPLOYMENT_TARGET  := XXX
WATCHOS_DEPLOYMENT_TARGET   := 2.0
MACOSX_DEPLOYMENT_TARGET    := 10.11
DARWIN_DEPLOYMENT_VERSION   := 15
override MEMO_CFVER         := 1200
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1300 ] && [ "$(CFVER_WHOLE)" -lt 1400 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 10.0
APPLETVOS_DEPLOYMENT_TARGET := 10.0
AUDIOOS_DEPLOYMENT_TARGET   := XXX
BRIDGEOS_DEPLOYMENT_TARGET  := 1.0 # bridgeOS 1.0 is T1 only
WATCHOS_DEPLOYMENT_TARGET   := 3.0
MACOSX_DEPLOYMENT_TARGET    := 10.12
DARWIN_DEPLOYMENT_VERSION   := 16
override MEMO_CFVER         := 1300
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 11.0
APPLETVOS_DEPLOYMENT_TARGET := 11.0
AUDIOOS_DEPLOYMENT_TARGET   := 11.0
BRIDGEOS_DEPLOYMENT_TARGET  := 2.0
WATCHOS_DEPLOYMENT_TARGET   := 4.0
MACOSX_DEPLOYMENT_TARGET    := 10.13
DARWIN_DEPLOYMENT_VERSION   := 17
override MEMO_CFVER         := 1400
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1500 ] && [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 12.0
APPLETVOS_DEPLOYMENT_TARGET := 12.0
AUDIOOS_DEPLOYMENT_TARGET   := 12.0
BRIDGEOS_DEPLOYMENT_TARGET  := 3.0
WATCHOS_DEPLOYMENT_TARGET   := 5.0
MACOSX_DEPLOYMENT_TARGET    := 10.14
DARWIN_DEPLOYMENT_VERSION   := 18
override MEMO_CFVER         := 1500
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 13.0
APPLETVOS_DEPLOYMENT_TARGET := 13.0
AUDIOOS_DEPLOYMENT_TARGET   := 13.0
BRIDGEOS_DEPLOYMENT_TARGET  := 4.0
WATCHOS_DEPLOYMENT_TARGET   := 6.0
MACOSX_DEPLOYMENT_TARGET    := 10.15
DARWIN_DEPLOYMENT_VERSION   := 19
override MEMO_CFVER         := 1600
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 14.0
APPLETVOS_DEPLOYMENT_TARGET := 14.0
AUDIOOS_DEPLOYMENT_TARGET   := 14.0
BRIDGEOS_DEPLOYMENT_TARGET  := 5.0
WATCHOS_DEPLOYMENT_TARGET   := 7.0
MACOSX_DEPLOYMENT_TARGET    := 11.0
DARWIN_DEPLOYMENT_VERSION   := 20
MACOSX_SUITE_NAME           := big_sur
override MEMO_CFVER         := 1700
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1800 ] && [ "$(CFVER_WHOLE)" -lt 1900 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 15.0
APPLETVOS_DEPLOYMENT_TARGET := 15.0
AUDIOOS_DEPLOYMENT_TARGET   := 15.0
BRIDGEOS_DEPLOYMENT_TARGET  := 6.0
WATCHOS_DEPLOYMENT_TARGET   := 8.0
MACOSX_DEPLOYMENT_TARGET    := 12.0
DARWIN_DEPLOYMENT_VERSION   := 21
MACOSX_SUITE_NAME           := monterey
override MEMO_CFVER         := 1800
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
LLVM_TARGET          := arm64-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM        := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),iphoneos-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS arm64e)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH            := arm64e
PLATFORM             := iphoneos
DEB_ARCH             := iphoneos-arm64e
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-ios
LLVM_TARGET          := arm64e-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
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
LLVM_TARGET          := arm64-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM        := AppleTVOS
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),appletvos-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for tvOS arm64e)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH            := arm64e
PLATFORM             := appletvos
DEB_ARCH             := appletvos-arm64e
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-tvos
LLVM_TARGET          := arm64e-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM        := AppleTVOS
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),audioos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for audioOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH            := arm64
PLATFORM             := appletvos # Platform-wise, audioos ~ appletvos (although some frameworks and stuff may be missing)
DEB_ARCH             := audioos-arm64
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-tvos
LLVM_TARGET          := arm64-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM        := AppleTVOS
export AUDIOOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),bridgeos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for BridgeOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH            := arm64
PLATFORM             := iphoneos # find me a BridgeOS.sdk and you win.
DEB_ARCH             := bridgeos-arm64
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := --target=arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-bridgeos
LLVM_TARGET          := arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX          ?=
MEMO_SUB_PREFIX      ?= /usr
MEMO_ALT_PREFIX      ?= /local
GNU_PREFIX           :=
ON_DEVICE_SDK_PATH   := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/BridgeOS.sdk
BARE_PLATFORM        := BridgeOS
export BRIDGEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),watchos-arm64_32)
ifneq ($(MEMO_QUIET),1)
$(warning Building for WatchOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH            := arm64_32
PLATFORM             := watchos
DEB_ARCH             := watchos-arm64-32
GNU_HOST_TRIPLE      := aarch64-apple-darwin
PLATFORM_VERSION_MIN := -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET)
RUST_TARGET          := aarch64-apple-watchos
LLVM_TARGET          := arm64-apple-watchos$(WATCHOS_DEPLOYMENT_TARGET)
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
LLVM_TARGET          := arm64e-apple-macosx$(MACOSX_DEPLOYMENT_TARGET)
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
LLVM_TARGET          := arm64-apple-macosx$(MACOSX_DEPLOYMENT_TARGET)
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
LLVM_TARGET          := x86_64-apple-macosx$(MACOSX_DEPLOYMENT_TARGET)
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
CPP             := $(shell xcrun --sdk $(PLATFORM) --find cc) -E
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
CC              := $(shell which cc)
CXX             := $(shell which c++)
CPP             := $(shell which cc) -E
PATH            := /usr/bin:$(PATH)

BUILD_CFLAGS   := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
BUILD_CPPFLAGS := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
BUILD_CXXFLAGS := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
BUILD_LDFLAGS  := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)

endif
AR              := $(shell which ar)
LD              := $(shell which ld)
RANLIB          := $(shell which ranlib)
STRIP           := $(shell which strip)
NM              := $(shell which nm)
LIPO            := $(shell which lipo)
OTOOL           := $(shell which otool)
I_N_T           := $(shell which install_name_tool)
LIBTOOL         := $(shell which libtool)

else
$(error Please use macOS, iOS, Linux, or FreeBSD to build)
endif

CC_FOR_BUILD  := $(shell which cc) $(BUILD_CFLAGS)
CPP_FOR_BUILD := $(shell which cc) -E $(BUILD_CPPFLAGS)
CXX_FOR_BUILD := $(shell which c++) $(BUILD_CXXFLAGS)
AR_FOR_BUILD  := $(shell which ar)
export CC_FOR_BUILD CPP_FOR_BUILD CXX_FOR_BUILD AR_FOR_BUILD

DEB_MAINTAINER    ?= Hayden Seay <me@diatr.us>
MEMO_REPO_URI     ?= https://apt.procurs.us
MEMO_PGP_SIGN_KEY ?= C59F3798A305ADD7E7E6C7256430292CF9551B0E
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
else ifeq ($(MEMO_TARGET),bridgeos-arm64)
OPTIMIZATION_FLAGS := -Oz
else
OPTIMIZATION_FLAGS := -Os
ifeq ($(UNAME),Darwin)
OPTIMIZATION_FLAGS += -flto=thin
else ifeq ($(MEMO_FORCE_LTO),1)
OPTIMIZATION_FLAGS += -flto=thin
# This flag will prevent ld64 from deleting the object file needed for dsymutil to work.
# I'm not setting this on macOS because I am unsure if it is needed.
# See: clang(1)
OPTIMIZATION_FLAGS += -Wl,-object_path_lto,/tmp/lto.o
endif
endif
ifdef ($(MEMO_ALT_LTO_LIB))
OPTIMIZATION_FLAGS += -lto_library $(MEMO_ALT_LTO_LIB)
endif

CFLAGS              := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
CPPFLAGS            := -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -Wno-error-implicit-function-declaration
LDFLAGS             := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
PKG_CONFIG_PATH     :=
ACLOCAL_PATH        := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal

ifeq ($(MEMO_TARGET),bridgeos-arm64)
CFLAGS              += -Wno-incompatible-sysroot
CXXFLAGS            += -Wno-incompatible-sysroot
endif

# Link everything to libiosexec, as it's preinstalled on every Procursus system.
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
LDFLAGS             += -liosexec
endif

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

BUILD_CONFIGURE_FLAGS := \
	--build=$$($(BUILD_MISC)/config.guess) \
	--host=$$($(BUILD_MISC)/config.guess) \
	--disable-dependency-tracking \
	CC="$(CC_FOR_BUILD)" \
	CXX="$(CXX_FOR_BUILD)" \
	CPP="$(CPP_FOR_BUILD)" \
	CFLAGS="$(BUILD_CFLAGS)" \
	CXXFLAGS="$(BUILD_CXXFLAGS)" \
	CPPFLAGS="$(BUILD_CPPFLAGS)" \
	LDFLAGS="$(BUILD_LDFLAGS)"

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
	CGO_CFLAGS="$(shell echo $(CFLAGS) | sed 's/$(OPTIMIZATION_FLAGS)//')" \
	CGO_CXXFLAGS="$(shell echo $(CXXFLAGS) | sed 's/$(OPTIMIZATION_FLAGS)//')" \
	CGO_CPPFLAGS="$(CPPFLAGS)" \
	CGO_LDFLAGS="$(shell echo $(LDFLAGS) | sed 's/$(OPTIMIZATION_FLAGS)//')" \
	CGO_ENABLED=1 \
	CC="$(CC)" \
	CXX="$(CXX)" \
	CPP="$(CPP)"

DEFAULT_SETUP_PY_ENV := \
	unset MACOSX_DEPLOYMENT_TARGET && \
	CFLAGS="$(CFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)" \
	CXXFLAGS="$(CXXFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)" \
	CPPFLAGS="$(CPPFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)"

DEFAULT_RUST_FLAGS := \
	SDKROOT="$(TARGET_SYSROOT)" \
	PKG_CONFIG="$(RUST_TARGET)-pkg-config"

export PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE MEMO_PREFIX MEMO_SUB_PREFIX MEMO_ALT_PREFIX
export CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T INSTALL
export BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS ACLOCAL_PATH PKG_CONFIG_PATH
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
		cp -a $(2)/. $(3); \
		rm -rf $(2); \
	fi; \
	find $(BUILD_BASE) -name '*.la' -type f -delete

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
				$(LDID) -S$(BUILD_MISC)/entitlements/$(2) $$file; \
			fi; \
		done; \
		find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete
else
SIGN = 	CODESIGN_FLAGS="--sign $(CODESIGN_IDENTITY) --force --deep "; \
		if [ "$(CODESIGN_IDENTITY)" != "-" ]; then \
			CODESIGN_FLAGS+="--timestamp -o runtime "; \
			if [ -n "$(3)" ]; then \
				CODESIGN_FLAGS+="--entitlements $(BUILD_MISC)/entitlements/$(3) "; \
			fi; \
		fi; \
		for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			$(STRIP) -x $$file; \
			codesign --remove $$file &> /dev/null; \
			codesign $$CODESIGN_FLAGS $$file &> /dev/null; \
		done
endif

###
#
# TODO: Please cleanup the PACK function, it's so horrible.
#
###

PACK = if [ -z "$(4)" ]; then \
		find $(BUILD_DIST)/$(1) -name '*.la' -type f -delete; \
	fi; \
	rm -f $(BUILD_DIST)/$(1)/.build_complete; \
	rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{info,doc}; \
	find $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -exec zstd -19 --rm '{}' \; 2> /dev/null; \
	if [ -z $(3) ]; then \
		if [ ! "$(MEMO_QUIET)" == "1" ]; then \
		echo Setting $(1) owner to 0:0.; \
		fi; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/* &>/dev/null; \
	elif [ $(3) = "2" ]; then \
		if [ ! "$(MEMO_QUIET)" == "1" ]; then \
		echo $(1) owner set within individual makefile.; \
		fi; \
	fi; \
	if [ -d "$(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale" ] && [ ! "$(shell grep Package: $(BUILD_INFO)/$(1).control | cut -f2 -d ' ')" = "gettext-localizations" ]; then \
		rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/*/LC_{MONETARY,TIME,COLLATE,CTYPE,NUMERIC}; \
	fi; \
	SIZE=$$(du -sk $(BUILD_DIST)/$(1) | cut -f 1); \
	mkdir -p $(BUILD_DIST)/$(1)/DEBIAN; \
	for i in control postinst preinst postrm prerm extrainst_ conffiles; do \
		for n in $$i $$i.$(PLATFORM); do \
			if [ -f "$(BUILD_INFO)/$(1).$$n" ]; then \
				$(SED) -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
					-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
					-e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' \
					-e 's|@GNU_PREFIX@|$(GNU_PREFIX)|g' \
					-e 's|@BARE_PLATFORM@|$(BARE_PLATFORM)|g' \
					-e 's/@$(2)@/$($(2))/g' \
					-e 's/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g' \
					-e 's/@DEB_ARCH@/$(DEB_ARCH)/g' < $(BUILD_INFO)/$(1).$$n > $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
			fi; \
		done; \
	done; \
	sed -i '$$a\' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	cd $(BUILD_DIST)/$(1) && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	if [ ! "$(MEMO_QUIET)" == "1" ]; then \
	echo "Installed-Size: $$SIZE"; \
	fi; \
	echo "Installed-Size: $$SIZE" >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
	find $(BUILD_DIST)/$(1) -name '.DS_Store' -type f -delete; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/$$(grep Package: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ')_$($(2))_$$(grep Architecture: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ').deb

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

ifneq ($(shell PATH=$(PATH) grep --version | grep -q GNU && echo 1),1)
$(error Install GNU grep)
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

ifneq  ($(shell PATH=$(PATH) file -bi $(BUILD_MISC)/launchctl.1700 | grep -q 'x-mach-binary; charset=binary' && echo 1),1)
$(error Install better file from Procursus - sudo apt install file)
endif

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
GET_LOGICAL_CORES := $(shell expr $(shell nproc) / 2)
else
GET_LOGICAL_CORES := $(shell expr $(shell sysctl -n hw.ncpu) / 2)
endif
MAKEFLAGS += --jobs=$(GET_LOGICAL_CORES) --load-average=$(GET_LOGICAL_CORES)
endif

PROCURSUS := 1

all:: package
	@echo "********** Successfully built debs for $(MEMO_TARGET) **********"
	@echo "$(SUBPROJECTS)"
	@MEMO_TARGET="$(MEMO_TARGET)" MEMO_CFVER="$(MEMO_CFVER)" '$(BUILD_TOOLS)/check_gettext.sh'

proenv:
	@echo -e "proenv() {"
	@echo -e "\tMEMO_TARGET='$(MEMO_TARGET)' PLATFORM='$(PLATFORM)' MEMO_ARCH='$(MEMO_ARCH)' TARGET_SYSROOT='$(TARGET_SYSROOT)' MACOSX_SYSROOT='$(MACOSX_SYSROOT)' GNU_HOST_TRIPLE='$(GNU_HOST_TRIPLE)'"
	@echo -e "\tCC='$(CC)' CXX='$(CXX)' AR='$(AR)' LD='$(LD)' CPP='$(CPP)' RANLIB='$(RANLIB)' STRIP='$(STRIP)' NM='$(NM)' LIPO='$(LIPO)' OTOOL='$(OTOOL)' I_N_T='$(I_N_T)' EXTRA='$(EXTRA)' SED='$(SED)' LDID='$(LDID)' INSTALL='$(INSTALL)' LN='$(LN)' CP='cp'"
	@echo -e "\tBUILD_ROOT='$(BUILD_ROOT)' BUILD_BASE='$(BUILD_BASE)' BUILD_INFO='$(BUILD_INFO)' BUILD_WORK='$(BUILD_WORK)' BUILD_STAGE='$(BUILD_STAGE)' BUILD_DIST='$(BUILD_DIST)' BUILD_STRAP='$(BUILD_STRAP)' BUILD_TOOLS='$(BUILD_TOOLS)'"
	@echo -e "\tDEB_ARCH='$(DEB_ARCH)' DEB_ORIGIN='$(DEB_ORIGIN)' DEB_MAINTAINER='$(DEB_MAINTAINER)'"
	@echo -e "\tCFLAGS='$(CFLAGS)'"
	@echo -e "\tCXXFLAGS='$(CXXFLAGS)'"
	@echo -e "\tCPPFLAGS='$(CPPFLAGS)'"
	@echo -e "\tLDFLAGS='$(LDFLAGS)'"
	@echo -e "\texport MEMO_TARGET PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE"
	@echo -e "\texport CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA SED LDID INSTALL LN CP"
	@echo -e "\texport BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS"
	@echo -e "\texport DEB_ARCH DEB_ORIGIN DEB_MAINTAINER"
	@echo -e "\texport CFLAGS CXXFLAGS CPPFLAGS LDFLAGS"
	@echo -e "}"

env:
	env

include makefiles/*.mk

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
	cd $(BUILD_STRAP) && rm -f !(apt_*|base_*|bash_*|ca-certificates_*|coreutils_*|darwintools_*|dash_*|debianutils_*|diffutils_*|diskdev-cmds_*|dpkg_*|essential_*|file-cmds_*|findutils_*|firmware-sbin_*|gpgv_*|grep_*|launchctl_*|libapt-pkg6.0_*|libassuan0_*|libcrypt2_*|libdimentio0_*|libedit0_*|libffi7_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|libiosexec1_*|libkernrw0_*liblz4-1_*|liblzma5_*|libmd0_*|libncursesw6_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libpam-modules_*|libpam2_*|libpcre1_*|libreadline8_*|libssl1.1_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|ncurses-bin_*|ncurses-term_*|openssh_*|openssh-client_*|openssh-server_*|openssh-sftp-server_*|procursus-keyring_*|profile.d_*|sed_*|shell-cmds_*|shshd_*|snaputil_*|sudo_*|system-cmds_*|tar_*|uikittools_*|zsh_*).deb
else # $(MEMO_TARGET),darwin-*
	cd $(BUILD_STRAP) && rm -f !(apt_*|ca-certificates_*|coreutils_*|darwintools_*|dpkg_*|gpgv_*|libapt-pkg6.0_*|libassuan0_*|libffi7_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|liblz4-1_*|liblzma5_*|libmd0_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|procursus-keyring_*|tar_*).deb
endif # $(MEMO_TARGET),darwin-*
	-for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		cp $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | $(SED) '1 s/$$/./' | $(SED) 's/\/$$//' > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.list; \
		for script in preinst postinst extrainst_ prerm postrm; do \
			cp $(BUILD_STRAP)/strap/DEBIAN/$$script $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.$$script; \
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
	cp $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/private/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/.procursus_strapped
	touch $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
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
	cp $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/.procursus_strapped
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MACOSX_SUITE_NAME)\n\
Components: main\n" > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
else
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
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
	gpg --armor -u $(MEMO_PGP_SIGN_KEY) -s $(BUILD_STRAP)/$${BOOTSTRAP}; \
	rm -rf $(BUILD_STRAP)/{strap,*.deb}; \
	echo "********** Successfully built bootstrap with **********"; \
	echo "$(STRAPPROJECTS)"; \
	echo "$(BUILD_STRAP)/$${BOOTSTRAP}"
endif # ($(MEMO_PREFIX),)

%-package: FAKEROOT=fakeroot -i $(BUILD_STAGE)/.fakeroot_$$(echo $@ | sed 's/\(.*\)-package/\1/') -s $(BUILD_STAGE)/.fakeroot_$$(echo $@ | sed 's/\(.*\)-package/\1/') --
%-package: .SHELLFLAGS=-O extglob -c
%-stage: %
	rm -f $(BUILD_STAGE)/.fakeroot_$*
	touch $(BUILD_STAGE)/.fakeroot_$*
	mkdir -p $(BUILD_DIST)

REPROJ=$(shell echo $@ | cut -f2- -d"-")
REPROJ2=$(shell echo $(REPROJ) | $(SED) 's/-package//' | $(SED) 's/-setup//')
rebuild-%:
	@echo Rebuild $(REPROJ2)
	-if [ $(REPROJ) = "all" ] || [ $(REPROJ) = "package" ]; then \
		rm -rf $(BUILD_WORK) $(BUILD_STAGE); \
	fi
	rm -rf {$(BUILD_WORK),$(BUILD_STAGE)}/$(REPROJ2)
	rm -rf $(BUILD_STAGE)/$(REPROJ2)
	+$(MAKE) $(REPROJ)

%-deps: %
	@${BUILD_TOOLS}/find_deps.sh $(BUILD_STAGE)/$^

.PHONY: $(SUBPROJECTS)

setup:
	@mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os,sys,IOKit,libkern,mach/machine},lib/pkgconfig,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libsyscall/wrappers/spawn/spawn.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/bootstrap_priv.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/vproc_priv.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/bsd/bsm/audit_kevents.h

	@cp -a $(BUILD_MISC)/{libxml-2.0,zlib}.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

ifeq ($(UNAME),FreeBSD)
	@# FreeBSD does not have stdbool.h and stdarg.h
	@cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool.h,stdarg.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@# Copy headers from MacOSX.sdk
	@cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,net,xpc,netinet,servers} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	@cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	@cp -af $(MACOSX_SYSROOT)/usr/include/kern $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,ptrace,kern*,random,reboot,user,vnode}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	@cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,libproc,NSSystemDirectories,tzfile,vproc}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
ifneq ($(wildcard $(BUILD_MISC)/IOKit.framework.$(PLATFORM)),)
	@cp -af $(BUILD_MISC)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework
endif

	@mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreAudio.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio

	@# Patch headers from iPhoneOS.sdk
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/time.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/task.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/mach_host.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ucontext.h
	@$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/signal.h
	@$(SED) -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pthread.h

	@# Setup libiosexec
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	@ln -sf libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.tbd
	@rm -f $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.*.dylib
	@$(SED) -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
endif

ifneq ($(MEMO_QUIET),1)
	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)
endif # ($(MEMO_QUIET),1)

clean::
	rm -rf $(BUILD_ROOT)/build_{base,stage,work}

extreme-clean: clean
	rm -rf $(BUILD_ROOT)/build_{source,strap,dist}

.PHONY: clean setup
