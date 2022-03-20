ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Procursus - sudo apt install make)
endif

export LANG := C

ifeq ($(shell LANG=C /usr/bin/env bash --version | grep -iq 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

# Unset sysroot, we manage that ourselves.
SYSROOT :=

UNAME           := $(shell uname -s)
UNAME_M         := $(shell uname -m)
SUBPROJECTS     += $(STRAPPROJECTS)

ifneq ($(shell umask),0022)
$(error Please run `umask 022` before running this)
endif

RELATIVE_RPATH       := 0

MEMO_TARGET          ?= darwin-arm64
MEMO_CFVER           ?= 1700
# iOS 13.0 == 1665.15.
CFVER_WHOLE          := $(shell echo $(MEMO_CFVER) | cut -d. -f1)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1800 ] && [ "$(CFVER_WHOLE)" -lt 1900 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 15.0
APPLETVOS_DEPLOYMENT_TARGET := 15.0
AUDIOOS_DEPLOYMENT_TARGET   := 15.0
BRIDGEOS_DEPLOYMENT_TARGET  := 6.0
WATCHOS_DEPLOYMENT_TARGET   := 8.0
MACOSX_DEPLOYMENT_TARGET    := 12.0
DARWIN_DEPLOYMENT_VERSION   := 21
MACOSX_SUITE_NAME           := monterey
override MEMO_CFVER         := 1800
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
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 13.0
APPLETVOS_DEPLOYMENT_TARGET := 13.0
AUDIOOS_DEPLOYMENT_TARGET   := 13.0
BRIDGEOS_DEPLOYMENT_TARGET  := 4.0
WATCHOS_DEPLOYMENT_TARGET   := 6.0
MACOSX_DEPLOYMENT_TARGET    := 10.15
DARWIN_DEPLOYMENT_VERSION   := 19
override MEMO_CFVER         := 1600
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1500 ] && [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 12.0
APPLETVOS_DEPLOYMENT_TARGET := 12.0
AUDIOOS_DEPLOYMENT_TARGET   := 12.0
BRIDGEOS_DEPLOYMENT_TARGET  := 3.0
WATCHOS_DEPLOYMENT_TARGET   := 5.0
MACOSX_DEPLOYMENT_TARGET    := 10.14
DARWIN_DEPLOYMENT_VERSION   := 18
override MEMO_CFVER         := 1500
else
$(error Unsupported CoreFoundation version)
endif

export MACOSX_DEPLOYMENT_TARGET

ifeq ($(shell [ "$(MEMO_TARGET)" = "iphoneos-arm64" ] || [ "$(MEMO_TARGET)" = "iphoneos-arm64-ramdisk" ] && echo 1),1)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
LLVM_TARGET           := arm64-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),iphoneos-arm64-rootless)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS with rootless prefix)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
LLVM_TARGET           := arm64-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /private/preboot/procursus
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),iphoneos-arm64e-rootless)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS arm64e with rootless prefix)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64e
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
LLVM_TARGET           := arm64e-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /private/preboot/procursus
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),iphoneos-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS arm64e)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64e
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
LLVM_TARGET           := arm64e-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),appletvos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for tvOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := appletvos
DEB_ARCH              := appletvos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-tvos
LLVM_TARGET           := arm64-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),appletvos-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for tvOS arm64e)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64e
PLATFORM              := appletvos
DEB_ARCH              := appletvos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-tvos
LLVM_TARGET           := arm64e-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
export APPLETVOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),audioos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for audioOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := appletvos # Platform-wise, audioos ~ appletvos (although some frameworks and stuff may be missing)
DEB_ARCH              := audioos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-tvos
LLVM_TARGET           := arm64-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
export AUDIOOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),bridgeos-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for BridgeOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos # find me a BridgeOS.sdk and you win.
DEB_ARCH              := bridgeos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := --target=arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-bridgeos
LLVM_TARGET           := arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/BridgeOS.sdk
BARE_PLATFORM         := BridgeOS
export BRIDGEOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),watchos-arm64_32)
ifneq ($(MEMO_QUIET),1)
$(warning Building for WatchOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64_32
PLATFORM              := watchos
DEB_ARCH              := watchos-arm64-32
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-watchos
LLVM_TARGET           := arm64-apple-watchos$(WATCHOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WatchOS.sdk
BARE_PLATFORM         := WatchOS
export WATCHOS_DEPLOYMENT_TARGET

else ifeq ($(shell [ "$(MEMO_TARGET)" = "watchos-armv7k" ] || [ "$(MEMO_TARGET)" = "watchos-armv7k-ramdisk" ] && echo 1),1)
ifneq ($(MEMO_QUIET),1)
$(warning Building for WatchOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := armv7k
PLATFORM              := watchos
DEB_ARCH              := watchos-armv7k
GNU_HOST_TRIPLE       := armv7k-apple-darwin
PLATFORM_VERSION_MIN  := -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET)
RUST_TARGET           := armv7k-apple-watchos
LLVM_TARGET           := armv7k-apple-watchos$(WATCHOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WatchOS.sdk
BARE_PLATFORM         := WatchOS
export WATCHOS_DEPLOYMENT_TARGET

else ifeq ($(MEMO_TARGET),darwin-arm64e)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS arm64e)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64e
PLATFORM              := macosx
DEB_ARCH              := darwin-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
LLVM_TARGET           := arm64e-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX

else ifeq ($(MEMO_TARGET),darwin-arm64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS arm64)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := arm64
PLATFORM              := macosx
DEB_ARCH              := darwin-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
LLVM_TARGET           := arm64-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX

else ifeq ($(MEMO_TARGET),darwin-amd64)
ifneq ($(MEMO_QUIET),1)
$(warning Building for macOS amd64)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := x86_64
PLATFORM              := macosx
DEB_ARCH              := darwin-amd64
GNU_HOST_TRIPLE       := x86_64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
LLVM_TARGET           := x86_64-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX

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
STRINGS  := $(GNU_HOST_TRIPLE)-strings
STRIP    := $(GNU_HOST_TRIPLE)-strip
I_N_T    := $(GNU_HOST_TRIPLE)-install_name_tool
NM       := $(GNU_HOST_TRIPLE)-nm
LIPO     := $(GNU_HOST_TRIPLE)-lipo
OTOOL    := $(GNU_HOST_TRIPLE)-otool
LIBTOOL  := $(GNU_HOST_TRIPLE)-libtool

CFLAGS_FOR_BUILD   := -O2 -pipe
CPPFLAGS_FOR_BUILD := -O2 -pipe
CXXFLAGS_FOR_BUILD := -O2 -pipe
LDFLAGS_FOR_BUILD  := -O2 -pipe

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
STRINGS := $(GNU_HOST_TRIPLE)-strings
STRIP   := $(GNU_HOST_TRIPLE)-strip
I_N_T   := $(GNU_HOST_TRIPLE)-install_name_tool
NM      := $(GNU_HOST_TRIPLE)-nm
LIPO    := $(GNU_HOST_TRIPLE)-lipo
OTOOL   := $(GNU_HOST_TRIPLE)-otool
LIBTOOL := $(GNU_HOST_TRIPLE)-libtool
PATH    := $(GNUBINDIR):$(PATH)

CFLAGS_FOR_BUILD   :=
CPPFLAGS_FOR_BUILD :=
CXXFLAGS_FOR_BUILD :=
LDFLAGS_FOR_BUILD  :=

else ifeq ($(UNAME),Darwin)
ifeq ($(shell sw_vers -productName),macOS) # Swap to Mac OS X for devices older than Big Sur
ifneq ($(MEMO_QUIET),1)
$(warning Building on MacOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= $(shell xcrun --sdk $(PLATFORM) --show-sdk-path)
MACOSX_SYSROOT  ?= $(shell xcrun --show-sdk-path)
CC              := $(shell xcrun --sdk $(PLATFORM) --find cc)
CXX             := $(shell xcrun --sdk $(PLATFORM) --find c++)
CPP             := $(shell xcrun --sdk $(PLATFORM) --find cc) -E
PATH            := /opt/procursus/bin:/opt/procursus/libexec/gnubin:/usr/bin:$(PATH)

CFLAGS_FOR_BUILD   := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
CPPFLAGS_FOR_BUILD := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
CXXFLAGS_FOR_BUILD := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
LDFLAGS_FOR_BUILD  := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)

else
ifneq ($(MEMO_QUIET),1)
$(warning Building on iOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= /usr/share/SDKs/$(BARE_PLATFORM).sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CC              := $(shell command -v cc)
CXX             := $(shell command -v c++)
CPP             := $(shell command -v cc) -E
PATH            := /usr/bin:$(PATH)

CFLAGS_FOR_BUILD   := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
CPPFLAGS_FOR_BUILD := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
CXXFLAGS_FOR_BUILD := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)
LDFLAGS_FOR_BUILD  := -arch $(shell uname -p) -miphoneos-version-min=$(shell sw_vers -productVersion)

endif
AR              := $(shell command -v ar)
LD              := $(shell command -v ld)
RANLIB          := $(shell command -v ranlib)
STRINGS         := $(shell command -v strings)
STRIP           := $(shell command -v strip)
NM              := $(shell command -v nm)
LIPO            := $(shell command -v lipo)
OTOOL           := $(shell command -v otool)
I_N_T           := $(shell command -v install_name_tool)
LIBTOOL         := $(shell command -v libtool)

else
$(error Please use macOS, iOS, Linux, or FreeBSD to build)
endif

CC_FOR_BUILD  := $(shell command -v cc) $(CFLAGS_FOR_BUILD)
CPP_FOR_BUILD := $(shell command -v cc) -E $(CPPFLAGS_FOR_BUILD)
CXX_FOR_BUILD := $(shell command -v c++) $(CXXFLAGS_FOR_BUILD)
AR_FOR_BUILD  := $(shell command -v ar)
export CC_FOR_BUILD CPP_FOR_BUILD CXX_FOR_BUILD AR_FOR_BUILD

DEB_MAINTAINER    ?= Procursus Team <support@procurs.us>
MEMO_REPO_URI     ?= https://apt.procurs.us
MEMO_PGP_SIGN_KEY ?= C59F3798A305ADD7E7E6C7256430292CF9551B0E
CODESIGN_IDENTITY ?= -

MEMO_LDID_EXTRA_FLAGS     ?=
MEMO_CODESIGN_EXTRA_FLAGS ?=

LDID := ldid -Cadhoc $(MEMO_LDID_EXTRA_FLAGS)

# Root
BUILD_ROOT     ?= $(PWD)
# Downloaded source files
BUILD_SOURCE   := $(BUILD_ROOT)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     := $(BUILD_ROOT)/build_base/$(MEMO_TARGET)/$(MEMO_CFVER)
# Dpkg info storage area
BUILD_INFO     ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_info
# Miscellaneous Procursus files
BUILD_MISC     ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_misc
# Patch storage area
BUILD_PATCH    ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_patch
# Extracted source working directory
BUILD_WORK     := $(BUILD_ROOT)/build_work/$(MEMO_TARGET)/$(MEMO_CFVER)
# Bootstrap working area
BUILD_STAGE    := $(BUILD_ROOT)/build_stage/$(MEMO_TARGET)/$(MEMO_CFVER)
# Final output
BUILD_DIST     := $(BUILD_ROOT)/build_dist/$(MEMO_TARGET)/$(MEMO_CFVER)
# Actual bootrap staging
BUILD_STRAP    := $(BUILD_ROOT)/build_strap/$(MEMO_TARGET)/$(MEMO_CFVER)
# Extra scripts for the buildsystem
BUILD_TOOLS    ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))/build_tools

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
ifneq ($(MEMO_NO_IOSEXEC),1)
LDFLAGS             += -liosexec
else
CFLAGS              += -DLIBIOSEXEC_INTERNAL
endif
endif

MEMO_MANPAGE_COMPRESSION := zstd

ifeq ($(MEMO_MANPAGE_COMPRESSION),zstd)
MEMO_MANPAGE_SUFFIX   := .zst
MEMO_MANPAGE_COMPCMD  := zstd
MEMO_MANPAGE_COMPFLGS += -19 --rm

else ifeq ($(MEMO_MANPAGE_COMPRESSION),xz)
MEMO_MANPAGE_SUFFIX    := .xz
MEMO_MANPAGE_COMPCMD   := xz
MEMO_MANPAGE_COMPFLGS  := -T0

else ifeq ($(MEMO_MANPAGE_COMPRESSION),gzip)
MEMO_MANPAGE_SUFFIX    := .gz
MEMO_MANPAGE_COMPCMD   := gzip
MEMO_MANPAGE_COMPFLGS  := -9

else ifeq ($(MEMO_MANPAGE_COMPRESSION),lz4)
MEMO_MANPAGE_SUFFIX    := .lz4
MEMO_MANPAGE_COMPCMD   := lz4

else ifeq ($(MEMO_MANPAGE_COMPRESSION),lzop)
MEMO_MANPAGE_SUFFIX    := .lzop
MEMO_MANPAGE_COMPCMD   := lzop
MEMO_MANPAGE_COMPFLGS  := -U

else ifeq ($(MEMO_MANPAGE_COMPRESSION),none)
MEMO_MANPAGE_SUFFIX    :=
MEMO_MANPAGE_COMPCMD   := true
endif

DEFAULT_CMAKE_FLAGS := \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CROSSCOMPILING=true \
	-DCMAKE_SYSTEM_NAME=Darwin \
	-DCMAKE_SYSTEM_PROCESSOR="$(shell echo $(GNU_HOST_TRIPLE) | cut -f1 -d-)" \
	-DCMAKE_C_FLAGS="$(CFLAGS)" \
	-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
	-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
	-DPKG_CONFIG_EXECUTABLE="$(BUILD_TOOLS)/cross-pkg-config" \
	-DCMAKE_INSTALL_NAME_TOOL="$(I_N_T)" \
	-DCMAKE_INSTALL_PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
	-DCMAKE_INSTALL_NAME_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
	-DCMAKE_INSTALL_RPATH="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
	-DCMAKE_INSTALL_SYSCONFDIR="$(MEMO_PREFIX)/etc" \
	-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
	-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)"

BUILD_CONFIGURE_FLAGS := \
	--build=$$($(BUILD_MISC)/config.guess) \
	--host=$$($(BUILD_MISC)/config.guess) \
	--disable-dependency-tracking \
	CC="$(CC_FOR_BUILD)" \
	CXX="$(CXX_FOR_BUILD)" \
	CPP="$(CPP_FOR_BUILD)" \
	CFLAGS="$(CFLAGS_FOR_BUILD)" \
	CXXFLAGS="$(CXXFLAGS_FOR_BUILD)" \
	CPPFLAGS="$(CPPFLAGS_FOR_BUILD)" \
	LDFLAGS="$(LDFLAGS_FOR_BUILD)"

DEFAULT_CONFIGURE_FLAGS := \
	--build=$$($(BUILD_MISC)/config.guess) \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	--localstatedir=$(MEMO_PREFIX)/var \
	--sysconfdir=$(MEMO_PREFIX)/etc \
	--bindir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	--mandir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
	--enable-silent-rules \
	--disable-dependency-tracking \
	--enable-shared \
	--enable-static

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
	CGO_CFLAGS="$(shell echo $(CFLAGS) | sed 's|$(OPTIMIZATION_FLAGS)||')" \
	CGO_CXXFLAGS="$(shell echo $(CXXFLAGS) | sed 's|$(OPTIMIZATION_FLAGS)||')" \
	CGO_CPPFLAGS="$(CPPFLAGS)" \
	CGO_LDFLAGS="$(shell echo $(LDFLAGS) | sed 's|$(OPTIMIZATION_FLAGS)||')" \
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

CHECKSUM_VERIFY = if [ "$(1)" = "sha1" ]; then \
			HASH=$$(sha1sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		elif [ "$(1)" = "sha256" ]; then \
			HASH=$$(sha256sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		elif [ "$(1)" = "sha512" ]; then \
			HASH=$$(sha512sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		fi; \
		if [ "$(3)" = "" ]; then \
			[ "$$(cut -d" " -f 1 "$(BUILD_SOURCE)/$(2).$(1)")" = "$$HASH" ] || (echo "$(2) - Invalid Hash" && exit 1); \
		else  \
			[ "$(3)" = "$$HASH" ] || (echo "$(2) - Invalid Hash" && exit 1); \
		fi

EXTRACT_TAR = -if [ ! -d $(BUILD_WORK)/$(3) ] || [ "$(4)" = "1" ]; then \
		cd $(BUILD_WORK) && \
		tar -xf $(BUILD_SOURCE)/$(1) && \
		mkdir -p $(3); \
		cp -a $(2)/. $(3); \
		rm -rf $(2); \
	fi

DO_PATCH    = cd $(BUILD_PATCH)/$(1); \
	for PATCHFILE in *; do \
		if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done ]; then \
			sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' -e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' $$PATCHFILE | patch -sN -d $(BUILD_WORK)/$(2) $(3) && \
			touch $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done; \
		fi; \
	done

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SIGN = 	for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
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
			CODESIGN_FLAGS+="--timestamp "; \
			if [ "$(4)" != "nohardened" ]; then \
				CODESIGN_FLAGS+="-o kill,hard "; \
			fi; \
			if [ -n "$(3)" ]; then \
				CODESIGN_FLAGS+="--entitlements $(BUILD_MISC)/entitlements/$(3) "; \
			fi; \
		fi; \
		for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			codesign --remove $$file &> /dev/null; \
			codesign $(MEMO_CODESIGN_EXTRA_FLAGS) $$CODESIGN_FLAGS $$file &> /dev/null; \
		done
endif

###
#
# TODO: Please cleanup the PACK function, it's so horrible.
#
###

AFTER_BUILD = \
	if [ ! -z "$(2)" ]; then \
		pkg="$(2)"; \
	else \
		pkg="$@"; \
	fi; \
	if [ ! -z "$(MEMO_PREFIX)" ] && [ -d "$(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" ]; then \
		rm -f $(BUILD_STAGE)/$$pkg/._lib_cache && touch $(BUILD_STAGE)/$$pkg/._lib_cache; \
		for file in $$(find $(BUILD_STAGE)/$$pkg -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			INSTALL_NAME=$$(otool -D $$file | grep -v ":$$"); \
			if [ ! -z "$$INSTALL_NAME" ]; then \
				$(I_N_T) -id @rpath/$$(basename $$INSTALL_NAME) $$file; \
				echo "$$INSTALL_NAME" >> $(BUILD_STAGE)/$$pkg/._lib_cache; \
			fi; \
		done; \
	fi; \
	for file in $$(find $(BUILD_STAGE)/$$pkg -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
		if [ "$(RELATIVE_RPATH)" = "1" ]; then \
			$(I_N_T) -add_rpath "@loader_path/$$(realpath --relative-to=$$(dirname $$file) $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX))/lib" $$file; \
		else \
			$(I_N_T) -add_rpath "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" $$file; \
		fi; \
		if [ -f $(BUILD_STAGE)/$$pkg/._lib_cache ]; then \
			cat $(BUILD_STAGE)/$$pkg/._lib_cache | while read line; do \
				$(I_N_T) -change $$line @rpath/$$(basename $$line) $$file; \
			done; \
		fi; \
		$(STRIP) -x $$file; \
	done; \
	rm -f $(BUILD_STAGE)/$$pkg/._lib_cache; \
	find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -name '*.gz$$' -exec gunzip '{}' \; 2> /dev/null; \
	find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -name '*.xz$$' -exec unxz '{}' \; 2> /dev/null; \
	find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -name '*.zst$$' -exec unzstd '{}' \; 2> /dev/null; \
	if [ "$(MEMO_NO_DOC_COMPRESS)" != 1 ]; then \
		find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -exec $(MEMO_MANPAGE_COMPCMD) $(MEMO_MANPAGE_COMPFLGS) '{}' \; 2> /dev/null; \
		find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type l -exec bash -c '$(LN_S) $$(readlink "{}" | sed -e "s/\.gz$$//" -e "s/\.xz$$//" -e "s/\.zst$$//")$(MEMO_MANPAGE_SUFFIX) "{}"$(MEMO_MANPAGE_SUFFIX); rm -f "{}"' \; -delete 2> /dev/null; \
	else \
		find $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type l -exec bash -c '$(LN_S) $$(readlink "{}" | sed -e "s/\.gz$$//" -e "s/\.xz$$//" -e "s/\.zst$$//") "{}"' \; 2> /dev/null; \
	fi; \
	if [ "$(1)" = "copy" ]; then \
		cp -af $(BUILD_STAGE)/$$pkg/* $(BUILD_BASE); \
	fi; \
	[ -d $(BUILD_WORK)/$$pkg/ ] || mkdir $(BUILD_WORK)/$$pkg/; \
	touch $(BUILD_WORK)/$$pkg/.build_complete; \
	find $(BUILD_BASE) -name '*.la' -type f -delete

PACK = \
	if [ -z "$(4)" ]; then \
		find $(BUILD_DIST)/$(1) -name '*.la' -type f -delete; \
	fi; \
	rm -f $(BUILD_DIST)/$(1)/.build_complete; \
	rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{info,doc}; \
	for file in AUTHORS COPYING LICENSE NEWS README THANKS TODO; do \
		if [ -f "$(BUILD_WORK)/$$(echo $@ | sed 's/-package//')/$$file" ]; then \
			mkdir -p $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1); \
			cp -aL $(BUILD_WORK)/$$(echo $@ | sed 's/-package//')/$$file $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1); \
			if [ "$(MEMO_NO_DOC_COMPRESS)" != 1 ]; then \
				if [ ! "$$file" = "AUTHORS" ] && [ ! "$$file" = "COPYING" ] && [ ! "$$file" = "LICENSE" ]; then \
					zstd -19 --rm $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1)/$$file 2> /dev/null; \
				fi; \
			fi; \
		fi; \
	done; \
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
	for i in control postinst preinst postrm prerm extrainst_ conffiles triggers; do \
		for n in $$i $$i.$(PLATFORM) $$i.$(PLATFORM); do \
			if [ -f "$(BUILD_INFO)/$(1).$$n.rootless" ] && [ ! -z "$(findstring rootless,$(MEMO_TARGET))" ]; then \
				sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
					-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
					-e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' \
					-e 's|@MEMO_LAUNCHCTL_PREFIX@|$(MEMO_LAUNCHCTL_PREFIX)|g' \
					-e 's|@GNU_PREFIX@|$(GNU_PREFIX)|g' \
					-e 's|@BARE_PLATFORM@|$(BARE_PLATFORM)|g' \
					-e 's/@$(2)@/$($(2))/g' \
					-e 's/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g' \
					-e 's/@MEMO_MANPAGE_SUFFIX@/$(MEMO_MANPAGE_SUFFIX)/g' \
					-e 's/@DEB_ARCH@/$(DEB_ARCH)/g' < $(BUILD_INFO)/$(1).$$n.rootless > $(BUILD_DIST)/$(1)/DEBIAN/$$i; \
			elif [ -f "$(BUILD_INFO)/$(1).$$n" ]; then \
				sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
					-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
					-e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' \
					-e 's|@MEMO_LAUNCHCTL_PREFIX@|$(MEMO_LAUNCHCTL_PREFIX)|g' \
					-e 's|@GNU_PREFIX@|$(GNU_PREFIX)|g' \
					-e 's|@BARE_PLATFORM@|$(BARE_PLATFORM)|g' \
					-e 's/@$(2)@/$($(2))/g' \
					-e 's/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g' \
					-e 's/@MEMO_MANPAGE_SUFFIX@/$(MEMO_MANPAGE_SUFFIX)/g' \
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

ifneq ($(shell PATH="$(PATH)" tar --version | grep -q GNU && echo 1),1)
$(error Install GNU tar)
endif

ifneq ($(shell PATH="$(PATH)" sed --version | grep -q GNU && echo 1),1)
$(error Install GNU sed)
endif

ifneq ($(shell PATH="$(PATH)" grep --version | grep -q GNU && echo 1),1)
$(error Install GNU grep)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifneq ($(call HAS_COMMAND,ldid),1)
$(error Install ldid)
endif
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

ifneq ($(shell PATH="$(PATH)" groff --version | grep -q 'version 1.2' && echo 1),1)
$(error Install newer groff)
endif

ifneq ($(shell PATH="$(PATH)" patch --version | grep -q 'GNU patch' && echo 1),1)
$(error Install GNU patch)
endif

ifneq ($(shell PATH="$(PATH)" find --version | grep -q 'GNU find' && echo 1),1)
$(error Install GNU findutils)
endif

ifeq ($(shell PATH="$(PATH)" install --version | grep -q 'GNU coreutils' && echo 1),1)
export INSTALL := $(shell PATH="$(PATH)" which install) --strip-program=$(STRIP)
export LN_S    := ln -sf
export LN_SR   := ln -sfr
else
$(error Install GNU coreutils)
endif

ifneq  ($(shell PATH="$(PATH)" file -bi $(BUILD_MISC)/launchctl/launchctl.1700 | grep -q 'x-mach-binary; charset=binary' && echo 1),1)
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
CORE_COUNT ?= $(shell nproc)
else
CORE_COUNT ?= $(shell sysctl -n hw.ncpu)
endif
MAKEFLAGS += --jobs=$(CORE_COUNT) --load-average=$(CORE_COUNT)
endif

PROCURSUS := 1

all:: package
	@echo "********** Successfully built debs for $(MEMO_TARGET) **********"
	@echo "$(SUBPROJECTS)"
	@MEMO_TARGET="$(MEMO_TARGET)" MEMO_CFVER="$(MEMO_CFVER)" '$(BUILD_TOOLS)/check_gettext.sh'

proenv:
	@echo -e "proenv() {"
	@echo -e "\tMEMO_TARGET='$(MEMO_TARGET)' PLATFORM='$(PLATFORM)' MEMO_ARCH='$(MEMO_ARCH)' TARGET_SYSROOT='$(TARGET_SYSROOT)' MACOSX_SYSROOT='$(MACOSX_SYSROOT)' GNU_HOST_TRIPLE='$(GNU_HOST_TRIPLE)'"
	@echo -e "\tCC='$(CC)' CXX='$(CXX)' AR='$(AR)' LD='$(LD)' CPP='$(CPP)' RANLIB='$(RANLIB)' STRIP='$(STRIP)' NM='$(NM)' LIPO='$(LIPO)' OTOOL='$(OTOOL)' I_N_T='$(I_N_T)' EXTRA='$(EXTRA)' INSTALL='$(INSTALL)'"
	@echo -e "\tBUILD_ROOT='$(BUILD_ROOT)' BUILD_BASE='$(BUILD_BASE)' BUILD_INFO='$(BUILD_INFO)' BUILD_WORK='$(BUILD_WORK)' BUILD_STAGE='$(BUILD_STAGE)' BUILD_DIST='$(BUILD_DIST)' BUILD_STRAP='$(BUILD_STRAP)' BUILD_TOOLS='$(BUILD_TOOLS)'"
	@echo -e "\tDEB_ARCH='$(DEB_ARCH)' DEB_ORIGIN='$(DEB_ORIGIN)' DEB_MAINTAINER='$(DEB_MAINTAINER)'"
	@echo -e "\tCFLAGS='$(CFLAGS)'"
	@echo -e "\tCXXFLAGS='$(CXXFLAGS)'"
	@echo -e "\tCPPFLAGS='$(CPPFLAGS)'"
	@echo -e "\tLDFLAGS='$(LDFLAGS)'"
	@echo -e "\texport MEMO_TARGET PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE"
	@echo -e "\texport CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T EXTRA INSTALL"
	@echo -e "\texport BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS"
	@echo -e "\texport DEB_ARCH DEB_ORIGIN DEB_MAINTAINER"
	@echo -e "\texport CFLAGS CXXFLAGS CPPFLAGS LDFLAGS"
	@echo -e "}"

env:
	env

include makefiles/*.mk

RAMDISK_PROJECTS := bash coreutils diskdev-cmds findutils grep gzip ncurses profile.d readline tar openssl libmd openssh

ramdisk:
	+MEMO_NO_IOSEXEC=1 $(MAKE) $(RAMDISK_PROJECTS:%=%-package)
	rm -rf $(BUILD_STRAP)/strap
	rm -f $(BUILD_DIST)/bootstrap_tools.tar*
	rm -f $(BUILD_DIST)/.fakeroot_bootstrap
	touch $(BUILD_DIST)/.fakeroot_bootstrap
	for DEB in $(BUILD_DIST)/*.deb; do \
		dpkg-deb -x $$DEB $(BUILD_DIST)/strap; \
	done
	ln -s $(MEMO_PREFIX)/bin/bash $(BUILD_DIST)/strap/$(MEMO_PREFIX)/bin/sh
	echo -e "/bin/sh\n" > $(BUILD_DIST)/strap/$(MEMO_PREFIX)/etc/shells
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/{*.a,pkgconfig},share/{doc,man}}
	export FAKEROOT='fakeroot -i $(BUILD_DIST)/.fakeroot_bootstrap -s $(BUILD_DIST)/.fakeroot_bootstrap --'; \
	cd $(BUILD_DIST)/strap && $$FAKEROOT tar -ckpf $(BUILD_DIST)/bootstrap_tools.tar .
	gzip -9 $(BUILD_DIST)/bootstrap_tools.tar
	rm -rf $(BUILD_DIST)/strap

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
	cd $(BUILD_STRAP) && rm -f !(apt_*|base_*|bash_*|ca-certificates_*|chariz-keyring_*|coreutils_*|darwintools_*|dash_*|debianutils_*|diffutils_*|diskdev-cmds_*|dpkg_*|essential_*|file-cmds_*|findutils_*|firmware-sbin_*|gpgv_*|grep_*|launchctl_*|libapt-pkg6.0_*|libassuan0_*|libcrypt2_*|libdimentio0_*|libedit0_*|libffi8_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|libiosexec1_*|libkernrw0_*|liblz4-1_*|liblzma5_*|libmd0_*|libncursesw6_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libpam-modules_*|libpam2_*|libpcre1_*|libreadline8_*|libssl3_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|ncurses-bin_*|ncurses-term_*|odyssey-keyring_*|openssh_*|openssh-client_*|openssh-server_*|openssh-sftp-server_*|packix-keyring_*|procursus-keyring_*|profile.d_*|sed_*|shell-cmds_*|shshd_*|snaputil_*|sudo_*|system-cmds_*|tar_*|uikittools_*|zsh_*).deb
else # $(MEMO_TARGET),darwin-*
	cd $(BUILD_STRAP) && rm -f !(apt_*|ca-certificates_*|coreutils_*|darwintools_*|dpkg_*|gpgv_*|libapt-pkg6.0_*|libassuan0_*|libffi8_*|libgcrypt20_*|libgmp10_*|libgnutls30_*|libgpg-error0_*|libhogweed6_*|libidn2-0_*|libintl8_*|liblz4-1_*|liblzma5_*|libmd0_*|libnettle8_*|libnpth0_*|libp11-kit0_*|libssl3_*|libtasn1-6_*|libunistring2_*|libxxhash0_*|libzstd1_*|procursus-keyring_*|tar_*).deb
endif # $(MEMO_TARGET),darwin-*
	-for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		cp $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | sed '1 s/$$/./' | sed 's/\/$$//' > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info/$$PKGNAME.list; \
		for script in preinst postinst extrainst_ prerm postrm conffiles triggers; do \
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
	cd $(BUILD_STRAP)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/$$mgr && $(LN_S) ../firmware.sh
	chmod 0775 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library
	mkdir -p $(BUILD_STRAP)/strap/private/etc/apt/preferences.d
	cp $(BUILD_INFO)/procursus.preferences $(BUILD_STRAP)/strap/private/etc/apt/preferences.d/procursus
	touch $(BUILD_STRAP)/strap/.procursus_strapped
	touch $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MEMO_TARGET)/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
	if [[ "$(SSH_STRAP)" = 1 ]]; then \
		sed -e 's/@SSH_STRAP@//' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/prep_bootstrap.sh; \
	else \
		sed -e '/@SSH_STRAP@/d' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/prep_bootstrap.sh; \
	fi; \
	chmod +x $(BUILD_STRAP)/strap/prep_bootstrap.sh; \
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
	$$FAKEROOT chown 0:80 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library; \
	$$FAKEROOT chown 0:3 $(BUILD_STRAP)/strap/private/var/empty; \
	$$FAKEROOT chown 0:1 $(BUILD_STRAP)/strap/private/var/run; \
	cd $(BUILD_STRAP)/strap && $$FAKEROOT tar -cf ../bootstrap.tar .
	@if [[ "$(SSH_STRAP)" = 1 ]]; then \
		BOOTSTRAP=bootstrap-ssh.tar.zst; \
	else \
		BOOTSTRAP=bootstrap.tar.zst; \
	fi; \
	zstd -qf -c19 --rm $(BUILD_STRAP)/bootstrap.tar > $(BUILD_STRAP)/$${BOOTSTRAP}; \
	gpg --armor -u $(MEMO_PGP_SIGN_KEY) --detach-sign $(BUILD_STRAP)/$${BOOTSTRAP}; \
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
	cd $(BUILD_STRAP)/strap && $$FAKEROOT tar -cf ../bootstrap.tar .
	@if [[ "$(SSH_STRAP)" = 1 ]]; then \
		BOOTSTRAP=bootstrap-ssh.tar.zst; \
	else \
		BOOTSTRAP=bootstrap.tar.zst; \
	fi; \
	zstd -qf -c19 --rm $(BUILD_STRAP)/bootstrap.tar > $(BUILD_STRAP)/$${BOOTSTRAP}; \
	gpg --armor -u $(MEMO_PGP_SIGN_KEY) --detch-sign $(BUILD_STRAP)/$${BOOTSTRAP}; \
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
REPROJ2=$(shell echo $(REPROJ) | sed 's/-package//' | sed 's/-setup//')
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
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os/internal,sys,firehose,CoreFoundation,SystemConfiguration,IOKit/{kext,pwr_mgt,ps,platform},libkern,arm,{mach/,}machine,xpc/private,CommonCrypto,Security,Kernel/kern/},lib/pkgconfig,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	@rm -rf $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/System
	@$(LN_SR) $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include{,/System}

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libsyscall/wrappers/spawn/spawn.h \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libsyscall/wrappers/spawn/spawn_private.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/bootstrap_priv.h \
		https://opensource.apple.com/source/launchd/launchd-842.92.1/liblaunch/vproc_priv.h \
		https://opensource.apple.com/source/libplatform/libplatform-126.1.2/include/_simple.h \
		https://opensource.apple.com/source/libutil/libutil-57/mntopts.h \
		https://opensource.apple.com/source/libutil/libutil-57/libutil.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/EXTERNAL_HEADERS/mach-o/nlist.h \
		https://github.com/samdmarshall/OSXPrivateSDK/raw/f4d52b60e86b496abfaffa119a7d299562d99783/PrivateSDK10.10.sparse.sdk/usr/local/include/IOReport.h \
		https://github.com/samdmarshall/OSXPrivateSDK/raw/f4d52b60e86b496abfaffa119a7d299562d99783/PrivateSDK10.10.sparse.sdk/usr/include/ne_{session,sm_bridge}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/kern/ https://opensource.apple.com/source/xnu/xnu-7195.101.1/osfmk/kern/ledger.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/arm \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/arm/disklabel.h \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/osfmk/arm/cpu_capabilities.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/machine/disklabel.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os \
		https://opensource.apple.com/source/Libc/Libc-1439.40.11/os/assumes.h \
		https://opensource.apple.com/source/libplatform/libplatform-126.1.2/include/os/base_private.h \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libkern/os/log_private.h \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libkern/os/log.h \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1506.40.4/os/variant_private.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CommonCrypto \
		https://opensource.apple.com/source/CommonCrypto/CommonCrypto-60118.30.2/include/CommonDigestSPI.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/SystemConfiguration \
		https://raw.githubusercontent.com/apple-oss-distributions/configd/configd-1163.40.8/SystemConfiguration.fproj/SC{{NetworkConnection,NetworkConfiguration,SchemaDefinitions,PreferencesSetSpecific,PreferencesGetSpecific,Preferences,DynamicStore,DynamicStoreCopySpecific,DynamicStoreSetSpecific,PreferencesKeychain,}Private,Validation,DPlugin}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/bsd/bsm/audit_kevents.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8019.41.5/iokit/IOKit/IO{HibernatePrivate,ReportTypes,ReportMacros,KitKeysPrivate}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/kext \
		https://opensource.apple.com/source/IOKitUser/IOKitUser-1845.81.1/kext.subproj/{KextManagerPriv,OSKext,OSKextPrivate,kextmanager_types,{fat,macho,misc}_util}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/pwr_mgt \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8019.41.5/iokit/IOKit/pwr_mgt/IOPMPrivate.h \
		https://github.com/apple-oss-distributions/IOKitUser/raw/main/pwr_mgt.subproj/{IOPM{Lib,UPS}Private.h,powermanagement{.defs,_mig.h}}

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/platform \
		https://github.com/apple-oss-distributions/IOKitUser/raw/main/platform.subproj/IOPlatformSupportPrivate.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/ps \
		https://github.com/apple-oss-distributions/IOKitUser/raw/IOKitUser-1955.40.6/ps.subproj/IO{PowerSources,PSKeys}Private.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security \
		https://opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-55050.9/lib/SecKeychainPriv.h \
		https://opensource.apple.com/source/libsecurity_codesigning/libsecurity_codesigning-55037.15/lib/Sec{CodeSigner,{Code,Requirement}Priv}.h \
		https://opensource.apple.com/source/Security/Security-55471/sec/Security/SecBasePriv.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation \
		https://opensource.apple.com/source/CF/CF-1153.18/CF{BundlePriv,Runtime}.h \
		https://github.com/samdmarshall/OSXPrivateSDK/raw/f4d52b60e86b496abfaffa119a7d299562d99783/PrivateSDK10.10.sparse.sdk/System/Library/Frameworks/CoreFoundation.framework/Versions/A/PrivateHeaders/CFXPCBridge.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/osfmk/machine/cpu_capabilities.h

	@wget -q -nc -P$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libkern/firehose/tracepoint_private.h \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libkern/firehose/firehose_types_private.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/libkern/libkern/{OSKextLibPrivate,mkext,prelink}.h \

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/internal \
		https://opensource.apple.com/source/libplatform/libplatform-126.50.8/include/os/internal/{internal_shared,atomic,crashlog}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/fsctl.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/spawn_internal.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/resource.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/event.h \
		https://opensource.apple.com/source/xnu/xnu-4903.221.2/bsd/sys/kdebug.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uuid \
		https://opensource.apple.com/source/Libc/Libc-1353.11.2/uuid/namespace.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach \
		https://opensource.apple.com/source/xnu/xnu-7195.101.1/osfmk/mach/coalition.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpc \
		https://github.com/darlinghq/darling-libxpc/raw/95ff73141553f22287547401aa4eacc53dfa59e8/include/xpc/{private,launchd,launchd_defs}.h

	@wget -q -nc -P $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpc/private \
		https://github.com/darlinghq/darling-libxpc/raw/95ff73141553f22287547401aa4eacc53dfa59e8/include/xpc/private/{bundle,date,endpoint,mach_recv,mach_send,pipe,plist}.h

	@cp -a $(BUILD_MISC)/{libxml-2.0,zlib}.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

ifeq ($(UNAME),FreeBSD)
	@# FreeBSD's LLVM does not have stdbool.h, stdatomic.h, and stdarg.h
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool,stdatomic,stdarg}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af /usr/include/stdalign.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@# Copy headers from MacOSX.sdk
	@cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,xpc,netinet,servers} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	@cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	@cp -af $(MACOSX_SYSROOT)/usr/include/kern $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,ptrace,kern*,random,reboot,user,vnode,disk,vmmeter,vnioctl,conf}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af  $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecDigestTransform,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,SecReadTransform,oids,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,SecEncryptTransform,cssmapi,cssmcli,mds,x509defs,oidsbase,SecSignVerifyTransform,cssmspi,cssmkrspi,SecTask,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,SecCustomTransform,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTransform,SecTrustSettings,SecStaticCode,emmspi,SecTransformReadTransform,SecKeychain,SecDecodeTransform,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecEncodeTransform,SecureDownload,SecAsn1Templates,AuthorizationDB,SecCertificateOIDs,cssmapple}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security
	@cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,libproc,nlist,NSSystemDirectories,tzfile,vproc}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
ifneq ($(wildcard $(BUILD_MISC)/IOKit.framework.$(PLATFORM)),)
	@cp -af $(BUILD_MISC)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework
endif

	@mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{CoreAudio,CoreFoundation}
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreAudio.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio

	@# Patch headers from $(BARE_PLATFORM).sdk
	@sed -E 's/API_UNAVAILABLE(ios, watchos, tvos)//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation/CFUserNotification.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/time.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/task.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/mach_host.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ucontext.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/signal.h
	@sed -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pthread.h
	@sed -E -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/var/tmp|! s|/var|$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/pwd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pwd.h
	@sed -E -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/var/tmp|! s|/var|$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/grp.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/grp.h
	@sed -E -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/var/tmp|! s|/var|$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/paths.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/paths.h

	@#Patch downloaded headers
	@sed -i -e '/ 0/d' -e '/ -4/d' -e '/ -34/d' -e '/ -36/d' -e '/ -49/d' -e '/ -50/d' -e '/ -61/d' -e '/ -108/d' -e '/ -128/d' -e '/ -909/d' -e '/ -2070/d' -e '/ -4960/d' -e '/ -34018/d' -e '/ -34020/d' -e '/ -25291/d' -e '/ -25292/d' -e '/ -25293/d' -e '/ -25294/d' -e '/ -25295/d' -e '/ -25296/d' -e '/ -25297/d' -e '/ -25298/d' -e '/ -25299/d' -e '/ -25300/d' -e '/ -25301/d' -e '/ -25302/d' -e '/ -25303/d' -e '/ -25304/d' -e '/ -25305/d' -e '/ -25306/d' -e '/ -25307/d' -e '/ -25308/d' -e '/ -25309/d' -e '/ -25310/d' -e '/ -25311/d' -e '/ -25312/d' -e '/ -25313/d' -e '/ -25314/d' -e '/ -25315/d' -e '/ -25316/d' -e '/ -25317/d' -e '/ -25318/d' -e '/ -25319/d' -e '/ -25320/d' -e '/ -25240/d' -e '/ -25241/d' -e '/ -25242/d' -e '/ -25243/d' -e '/ -25244/d' -e '/ -25245/d' -e '/ -25256/d' -e '/ -25257/d' -e '/ -25258/d' -e '/ -25259/d' -e '/ -25260/d' -e '/ -25261/d' -e '/ -25262/d' -e '/ -25263/d' -e '/ -25264/d' -e '/ -26267/d' -e '/ -26275/d' -e '/ -67585/d' -e '/ -67586/d' -e '/ -67587/d' -e '/ -67588/d' -e '/ -67589/d' -e '/ -67590/d' -e '/ -67591/d' -e '/ -67592/d' -e '/ -67593/d' -e '/ -67594/d' -e '/ -67595/d' -e '/ -67596/d' -e '/ -67597/d' -e '/ -67598/d' -e '/ -67599/d' -e '/ -67600/d' -e '/ -67601/d' -e '/ -67602/d' -e '/ -67603/d' -e '/ -67604/d' -e '/ -67605/d' -e '/ -67606/d' -e '/ -67607/d' -e '/ -67608/d' -e '/ -67609/d' -e '/ -67610/d' -e '/ -67611/d' -e '/ -67612/d' -e '/ -67613/d' -e '/ -67614/d' -e '/ -67615/d' -e '/ -67616/d' -e '/ -67617/d' -e '/ -67618/d' -e '/ -67619/d' -e '/ -67620/d' -e '/ -67621/d' -e '/ -67622/d' -e '/ -67623/d' -e '/ -67624/d' -e '/ -67625/d' -e '/ -67626/d' -e '/ -67627/d' -e '/ -67628/d' -e '/ -67629/d' -e '/ -67630/d' -e '/ -67631/d' -e '/ -67632/d' -e '/ -67633/d' -e '/ -67634/d' -e '/ -67635/d' -e '/ -67636/d' -e '/ -67637/d' -e '/ -67638/d' -e '/ -67639/d' -e '/ -67640/d' -e '/ -67641/d' -e '/ -67642/d' -e '/ -67643/d' -e '/ -67644/d' -e '/ -67645/d' -e '/ -67646/d' -e '/ -67647/d' -e '/ -67648/d' -e '/ -67649/d' -e '/ -67650/d' -e '/ -67651/d' -e '/ -67652/d' -e '/ -67653/d' -e '/ -67654/d' -e '/ -67655/d' -e '/ -67656/d' -e '/ -67657/d' -e '/ -67658/d' -e '/ -67659/d' -e '/ -67660/d' -e '/ -67661/d' -e '/ -67662/d' -e '/ -67663/d' -e '/ -67664/d' -e '/ -67665/d' -e '/ -67666/d' -e '/ -67667/d' -e '/ -67668/d' -e '/ -67669/d' -e '/ -67670/d' -e '/ -67671/d' -e '/ -67672/d' -e '/ -67673/d' -e '/ -67674/d' -e '/ -67675/d' -e '/ -67676/d' -e '/ -67677/d' -e '/ -67678/d' -e '/ -67679/d' -e '/ -67680/d' -e '/ -67681/d' -e '/ -67682/d' -e '/ -67683/d' -e '/ -67684/d' -e '/ -67685/d' -e '/ -67686/d' -e '/ -67687/d' -e '/ -67688/d' -e '/ -67689/d' -e '/ -67690/d' -e '/ -67691/d' -e '/ -67692/d' -e '/ -67693/d' -e '/ -67694/d' -e '/ -67695/d' -e '/ -67696/d' -e '/ -67697/d' -e '/ -67698/d' -e '/ -67699/d' -e '/ -67700/d' -e '/ -67701/d' -e '/ -67702/d' -e '/ -67703/d' -e '/ -67704/d' -e '/ -67705/d' -e '/ -67706/d' -e '/ -67707/d' -e '/ -67708/d' -e '/ -67709/d' -e '/ -67710/d' -e '/ -67711/d' -e '/ -67712/d' -e '/ -67713/d' -e '/ -67714/d' -e '/ -67715/d' -e '/ -67716/d' -e '/ -67717/d' -e '/ -67718/d' -e '/ -67719/d' -e '/ -67720/d' -e '/ -67721/d' -e '/ -67722/d' -e '/ -67723/d' -e '/ -67724/d' -e '/ -67725/d' -e '/ -67726/d' -e '/ -67727/d' -e '/ -67728/d' -e '/ -67729/d' -e '/ -67730/d' -e '/ -67731/d' -e '/ -67732/d' -e '/ -67733/d' -e '/ -67734/d' -e '/ -67735/d' -e '/ -67736/d' -e '/ -67737/d' -e '/ -67738/d' -e '/ -67739/d' -e '/ -67740/d' -e '/ -67741/d' -e '/ -67742/d' -e '/ -67743/d' -e '/ -67744/d' -e '/ -67745/d' -e '/ -67746/d' -e '/ -67747/d' -e '/ -67748/d' -e '/ -67749/d' -e '/ -67750/d' -e '/ -67751/d' -e '/ -67752/d' -e '/ -67753/d' -e '/ -67754/d' -e '/ -67755/d' -e '/ -67756/d' -e '/ -67757/d' -e '/ -67758/d' -e '/ -67759/d' -e '/ -67760/d' -e '/ -67761/d' -e '/ -67762/d' -e '/ -67763/d' -e '/ -67764/d' -e '/ -67765/d' -e '/ -67766/d' -e '/ -67767/d' -e '/ -67768/d' -e '/ -67769/d' -e '/ -67770/d' -e '/ -67771/d' -e '/ -67772/d' -e '/ -67773/d' -e '/ -67774/d' -e '/ -67775/d' -e '/ -67776/d' -e '/ -67777/d' -e '/ -67778/d' -e '/ -67779/d' -e '/ -67780/d' -e '/ -67781/d' -e '/ -67782/d' -e '/ -67783/d' -e '/ -67784/d' -e '/ -67785/d' -e '/ -67786/d' -e '/ -67787/d' -e '/ -67788/d' -e '/ -67789/d' -e '/ -67790/d' -e '/ -67791/d' -e '/ -67792/d' -e '/ -67793/d' -e '/ -67794/d' -e '/ -67795/d' -e '/ -67796/d' -e '/ -67797/d' -e '/ -67798/d' -e '/ -67799/d' -e '/ -67800/d' -e '/ -67801/d' -e '/ -67802/d' -e '/ -67803/d' -e '/ -67804/d' -e '/ -67805/d' -e '/ -67806/d' -e '/ -67807/d' -e '/ -67808/d' -e '/ -67809/d' -e '/ -67810/d' -e '/ -67811/d' -e '/ -67812/d' -e '/ -67813/d' -e '/ -67814/d' -e '/ -67815/d' -e '/ -67816/d' -e '/ -67817/d' -e '/ -67818/d' -e '/ -67819/d' -e '/ -67820/d' -e '/ -67821/d' -e '/ -67822/d' -e '/ -67823/d' -e '/ -67824/d' -e '/ -67825/d' -e '/ -67826/d' -e '/ -67827/d' -e '/ -67828/d' -e '/ -67829/d' -e '/ -67830/d' -e '/ -67831/d' -e '/ -67832/d' -e '/ -67833/d' -e '/ -67834/d' -e '/ -67835/d' -e '/ -67836/d' -e '/ -67837/d' -e '/ -67838/d' -e '/ -67839/d' -e '/ -67840/d' -e '/ -67841/d' -e '/ -67842/d' -e '/ -67843/d' -e '/ -67844/d' -e '/ -67845/d' -e '/ -67846/d' -e '/ -67847/d' -e '/ -67848/d' -e '/ -67849/d' -e '/ -67850/d' -e '/ -67851/d' -e '/ -67852/d' -e '/ -67853/d' -e '/ -67854/d' -e '/ -67855/d' -e '/ -67856/d' -e '/ -67857/d' -e '/ -67858/d' -e '/ -67859/d' -e '/ -67860/d' -e '/ -67861/d' -e '/ -67862/d' -e '/ -67863/d' -e '/ -67864/d' -e '/ -67865/d' -e '/ -67866/d' -e '/ -67867/d' -e '/ -67868/d' -e '/ -67869/d' -e '/ -67870/d' -e '/ -67871/d' -e '/ -67872/d' -e '/ -67873/d' -e '/ -67874/d' -e '/ -67875/d' -e '/ -67876/d' -e '/ -67877/d' -e '/ -67878/d' -e '/ -67879/d' -e '/ -67880/d' -e '/ -67881/d' -e '/ -67882/d' -e '/ -67883/d' -e '/ -67884/d' -e '/ -67885/d' -e '/ -67886/d' -e '/ -67887/d' -e '/ -67888/d' -e '/ -67889/d' -e '/ -67890/d' -e '/ -67891/d' -e '/ -67892/d' -e '/ -67893/d' -e '/ -67894/d' -e '/ -67895/d' -e '/ -67896/d' -e '/ -67897/d' -e '/ -67898/d' -e '/ -67899/d' -e '/ -67900/d' -e '/ -67901/d' -e '/ -67902/d' $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecBasePriv.h
	@sed -i '1s|^|#include <Security/cssmapi.h>\n#include <Security/SecKeychain.h>\n|' $(BUILD_BASE)$(PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecKeychainPriv.h
	@sed -i '1s|^|#include <machine/cpu_capabilities.h>\n|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose/tracepoint_private.h
	@sed -i 's|extern void \*__dso_handle;|#ifndef __OS_TRACE_BASE_H__\nextern void \*__dso_handle;\n#endif|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/log.h
	@sed -i 's|__OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_NA);|__OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_2_0);|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/pwr_mgt/IOPMLibPrivate.h
	@sed -i 's|, bridgeos(4.0)||g' $(BUILD_BASE)$(PREFIX)$(MEMO_SUB_PREFIX)/include/os/variant_private.h
	@sed -i 's|#include <SystemConfiguration/SCPreferencesKeychainPrivate.h>|#include <SystemConfiguration/SCPreferencesKeychainPrivate.h>\ntypedef uint8_t os_log_pack_t;|g' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/SystemConfiguration/SCPrivate.h

	@# Setup libiosexec
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.1.tbd
	@$(LN_S) libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.tbd
	@rm -f $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.*.dylib
ifneq ($(MEMO_NO_IOSEXEC),1)
	@sed -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/spawn.h
endif
endif

ifneq ($(MEMO_QUIET),1)
	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)
endif # ($(MEMO_QUIET),1)

clean::
	rm -rf $(BUILD_ROOT)/build_{base,stage,work}

extreme-clean: clean
	rm -rf $(BUILD_ROOT)/build_{source,strap,dist}

define mootext
                 (__)
                 (oo)
           /------\/
          / |    ||
         *  /\---/\
            ~~   ~~
..."Have you mooed today?"...
endef
define helptext
$(MAKE)                        - Compiles the entire Procursus suite and packs it into debian packages.
$(MAKE) help                   - Display this text
$(MAKE) (tool)                 - Used to compile only a specified tool.
$(MAKE) (tool)-package         - Used to compile only a specified tool and pack it into a debian package.
$(MAKE) rebuild-(tool)         - Used to recompile only a specified tool after it's already been compiled before.
$(MAKE) rebuild-(tool)-package - Used to recompile only a specified tool after it's already been compiled before and pack it into a debian package.
$(MAKE) clean                  - Clean out $(BUILD_STAGE), $(BUILD_BASE), and $(BUILD_WORK).
$(MAKE) extreme-clean          - Runs `$(MAKE) clean`and cleans out $(BUILD_DIST).
$(MAKE) proenv                 - Print the proenv shell function to STDOUT to give a cross-compilation environment in your POSIX shell (make proenv >> ~/.zshrc)
$(MAKE) env                    - Print the environment variables inside the makefile
$(MAKE) (tool)-deps            - Print the dylibs linked by (tool)

Some influential environmental variables:
MEMO_TARGET     Can be set to any of the supported host systems. Pretty self explainatory. (Defaults to darwin-arm64)
MEMO_CFVER      Used to set minimum *OS version to compile for. Use the CoreFoundation version that coresponds to the OS version you're compiling for. (Defaults to 1700 for iOS 14)
NO_PGP          Set to 1 if you want to bypass verifying tarballs with gpg. Useful if you just want a quick build without importing everyone's public keys.
TARGET_SYSROOT  Path to your chosen iPhone SDK. (Defaults to Xcode default path on macOS and the cctools-port default path on Linux.)
MACOSX_SYSROOT  Path to your chosen macOS SDK. (Defaults to Xcode default path on macOS and the cctools-port default path on Linux.)
BUILD_ROOT      If you have this repo in one place, but want to build everything in a different place, set BUILD_ROOT to said different place. (Untested but should work fine.)
MEMO_QUIET      Mute unnecessary warnings and echos.

Report issues to: https://github.com/ProcursusTeam/Procursus/issues
For extra and updated help please refer to thr wiki: https://github.com/ProcursusTeam/Procursus/wiki

This Makefile has super cow powers.
endef
export mootext helptext
moo:
	@echo "$$mootext"
help:
	@echo "$$helptext"

print-%:
	@echo '$($*)'

%-download: setup
	BUILD_BASE="$(BUILD_BASE)" BUILD_DIST="$(BUILD_DIST)" BUILD_WORK="$(BUILD_WORK)" DEB_ARCH="$(DEB_ARCH)" MACOSX_SUITE_NAME="$(MACOSX_SUITE_NAME)" MAKE="$(MAKE)" MEMO_CFVER="$(MEMO_CFVER)" MEMO_TARGET="$(MEMO_TARGET)" $(BUILD_TOOLS)/setup_base.sh '$*'

.PHONY: clean setup
