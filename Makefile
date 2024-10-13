ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Procursus - sudo apt install make)
endif

# Comma var must be here because makefile functions cannot contain commas
comma := ,

SAVED_LANG = $(LANG)
export LANG := C
export LD_SHARED_CACHE_ELIGIBLE = NO


ifeq ($(shell LANG=C /usr/bin/env bash --version | grep -iq 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

# Unset sysroot, we manage that ourselves.
SYSROOT :=
PERL_MM_OPT :=

UNAME           != uname -s
UNAME_M         != uname -m
SUBPROJECTS     += $(STRAPPROJECTS)

ifneq ($(shell umask),0022)
$(error Please run `umask 022` before running this)
endif

RELATIVE_RPATH       := 0

MEMO_TARGET          ?= darwin-arm64
MEMO_CFVER           ?= 1800
# iOS 13.0 == 1665.15.
CFVER_WHOLE          != echo $(MEMO_CFVER) | cut -d. -f1

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 3000 ] && [ "$(CFVER_WHOLE)" -lt 4000 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 18.0
APPLETVOS_DEPLOYMENT_TARGET := 18.0
AUDIOOS_DEPLOYMENT_TARGET   := 18.0
BRIDGEOS_DEPLOYMENT_TARGET  := 9.0
WATCHOS_DEPLOYMENT_TARGET   := 11.0
MACOSX_DEPLOYMENT_TARGET    := 15.0
DARWIN_DEPLOYMENT_VERSION   := 24
MACOSX_SUITE_NAME           := sequoia
override MEMO_CFVER         := 3000
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && [ "$(CFVER_WHOLE)" -lt 3000 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 17.0
APPLETVOS_DEPLOYMENT_TARGET := 17.0
AUDIOOS_DEPLOYMENT_TARGET   := 17.0
BRIDGEOS_DEPLOYMENT_TARGET  := 8.0
WATCHOS_DEPLOYMENT_TARGET   := 10.0
MACOSX_DEPLOYMENT_TARGET    := 14.0
DARWIN_DEPLOYMENT_VERSION   := 23
MACOSX_SUITE_NAME           := sonoma
override MEMO_CFVER         := 2000
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && [ "$(CFVER_WHOLE)" -lt 2000 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 16.0
APPLETVOS_DEPLOYMENT_TARGET := 16.0
AUDIOOS_DEPLOYMENT_TARGET   := 16.0
BRIDGEOS_DEPLOYMENT_TARGET  := 7.0
WATCHOS_DEPLOYMENT_TARGET   := 9.0
MACOSX_DEPLOYMENT_TARGET    := 13.0
DARWIN_DEPLOYMENT_VERSION   := 22
MACOSX_SUITE_NAME           := ventura
override MEMO_CFVER         := 1900
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
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1200 ] && [ "$(CFVER_WHOLE)" -lt 1300 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 9.0
APPLETVOS_DEPLOYMENT_TARGET := 9.0
AUDIOOS_DEPLOYMENT_TARGET   := 9.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.11
DARWIN_DEPLOYMENT_VERSION   := 15
override MEMO_CFVER         := 1200
else
$(error Unsupported CoreFoundation version)
endif

ifeq ($(shell [ "$(MEMO_TARGET)" = "iphoneos-arm64" ] || [ "$(MEMO_TARGET)" = "iphoneos-arm64-ramdisk" ] && echo 1),1)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
GOLANG_OS             := ios
LLVM_TARGET           := arm64-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),iphoneos-arm64-rootless)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
GOLANG_OS             := ios
LLVM_TARGET           := arm64-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /var/jb
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),iphoneos-arm64e-rootless)
MEMO_ARCH             := arm64e
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
GOLANG_OS             := ios
LLVM_TARGET           := arm64e-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /var/jb
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),iphoneos-arm64e)
MEMO_ARCH             := arm64e
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-ios
GOLANG_OS             := ios
LLVM_TARGET           := arm64e-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(shell [ "$(MEMO_TARGET)" = "iphoneos-armv7" ] || [ "$(MEMO_TARGET)" = "iphoneos-armv7-ramdisk" ] && echo 1),1)
MEMO_ARCH             := armv7
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm
GNU_HOST_TRIPLE       := armv7-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := armv7-apple-ios
GOLANG_OS             := ios
LLVM_TARGET           := armv7-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(shell [ "$(MEMO_TARGET)" = "appletvos-arm64" ] || [ "$(MEMO_TARGET)" = "appletvos-arm64-ramdisk" ] && echo 1),1)
MEMO_ARCH             := arm64
PLATFORM              := appletvos
DEB_ARCH              := appletvos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-tvos
GOLANG_OS             := ios
LLVM_TARGET           := arm64-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
MEMO_DEPLOYMENT       := APPLETVOS_DEPLOYMENT_TARGET=$(APPLETVOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),appletvos-arm64e)
MEMO_ARCH             := arm64e
PLATFORM              := appletvos
DEB_ARCH              := appletvos-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mappletvos-version-min=$(APPLETVOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-tvos
GOLANG_OS             := ios
LLVM_TARGET           := arm64e-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
MEMO_DEPLOYMENT       := APPLETVOS_DEPLOYMENT_TARGET=$(APPLETVOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),bridgeos-arm64)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos # find me a BridgeOS.sdk and you win.
DEB_ARCH              := bridgeos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := --target=arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-bridgeos
GOLANG_OS             := ios
LLVM_TARGET           := arm64-apple-bridgeos$(BRIDGEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/BridgeOS.sdk
BARE_PLATFORM         := BridgeOS
MEMO_DEPLOYMENT       := BRIDGEOS_DEPLOYMENT_TARGET=$(BRIDGEOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),watchos-arm64_32)
MEMO_ARCH             := arm64_32
PLATFORM              := watchos
DEB_ARCH              := watchos-arm64-32
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET)
RUST_TARGET           := arm64_32-apple-watchos
GOLANG_OS             := ios
LLVM_TARGET           := arm64_32-apple-watchos$(WATCHOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WatchOS.sdk
BARE_PLATFORM         := WatchOS
MEMO_DEPLOYMENT       := WATCHOS_DEPLOYMENT_TARGET=$(WATCHOS_DEPLOYMENT_TARGET)

else ifeq ($(shell [ "$(MEMO_TARGET)" = "watchos-armv7k" ] || [ "$(MEMO_TARGET)" = "watchos-armv7k-ramdisk" ] && echo 1),1)
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
MEMO_DEPLOYMENT       := WATCHOS_DEPLOYMENT_TARGET=$(WATCHOS_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),darwin-arm64e)
MEMO_ARCH             := arm64e
PLATFORM              := macosx
DEB_ARCH              := darwin-arm64e
GNU_HOST_TRIPLE       := aarch64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
GOLANG_OS             := darwin
LLVM_TARGET           := arm64e-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX
MEMO_DEPLOYMENT       := MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),darwin-arm64)
MEMO_ARCH             := arm64
PLATFORM              := macosx
DEB_ARCH              := darwin-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
GOLANG_OS             := darwin
LLVM_TARGET           := arm64-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX
MEMO_DEPLOYMENT       := MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)

else ifeq ($(MEMO_TARGET),darwin-amd64)
MEMO_ARCH             := x86_64
PLATFORM              := macosx
DEB_ARCH              := darwin-amd64
GNU_HOST_TRIPLE       := x86_64-apple-darwin
RUST_TARGET           := $(GNU_HOST_TRIPLE)
GOLANG_OS             := darwin
LLVM_TARGET           := x86_64-apple-macos$(MACOSX_DEPLOYMENT_TARGET)
PLATFORM_VERSION_MIN  := -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?= /opt/procursus
MEMO_SUB_PREFIX       ?=
MEMO_ALT_PREFIX       ?=
MEMO_LAUNCHCTL_PREFIX ?=
GNU_PREFIX            := g
ON_DEVICE_SDK_PATH    := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
BARE_PLATFORM         := MacOSX
MEMO_DEPLOYMENT       := MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)

else
$(error Platform not supported)
endif


ifneq ($(MEMO_QUIET),1)
$(warning Building for $(BARE_PLATFORM) $(MEMO_ARCH) with CoreFoundation version $(MEMO_CFVER) and prefix $(MEMO_PREFIX))
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
CPPFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
CXXFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
ASFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)
LDFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)

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
ASFLAGS_FOR_BUILD  :=
LDFLAGS_FOR_BUILD  :=

else ifeq ($(UNAME),Darwin)
ifeq ($(shell sw_vers -productName),macOS) # Swap to Mac OS X for devices older than Big Sur
ifneq ($(MEMO_QUIET),1)
$(warning Building on MacOS)
endif # ($(MEMO_QUIET),1)
ifeq ($(origin TARGET_SYSROOT), undefined)
TARGET_SYSROOT  != xcrun --sdk $(PLATFORM) --show-sdk-path
endif
ifeq ($(origin MACOSX_SYSROOT), undefined)
MACOSX_SYSROOT  != xcrun --show-sdk-path
endif
CC              != xcrun --find cc
CXX             != xcrun --find c++
CPP             := $(CC) -E
PATH            := /opt/procursus/bin:/opt/procursus/libexec/gnubin:/usr/bin:$(PATH)

CFLAGS_FOR_BUILD   := -arch $(shell uname -m) -mmacosx-version-min=$(shell sw_vers -productVersion) -isysroot $(MACOSX_SYSROOT)
CPPFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
CXXFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
ASFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)
LDFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)

else ifeq ($(shell sw_vers -productName),iPhone OS)
ifneq ($(MEMO_QUIET),1)
$(warning Building on iOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= /usr/share/SDKs/$(BARE_PLATFORM).sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CC              != command -v cc
CXX             != command -v c++
CPP             := $(CC) -E
PATH            := /usr/bin:$(PATH)

CFLAGS_FOR_BUILD   := -arch $(shell arch) -miphoneos-version-min=$(shell sw_vers -productVersion)
CPPFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
CXXFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
ASFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)
LDFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)

else ifeq ($(shell sw_vers -productName),Apple TVOS)
ifneq ($(MEMO_QUIET),1)
$(warning Building on tvOS)
endif # ($(MEMO_QUIET),1)
TARGET_SYSROOT  ?= /usr/share/SDKs/$(BARE_PLATFORM).sdk
MACOSX_SYSROOT  ?= /usr/share/SDKs/MacOSX.sdk
CC              != command -v cc
CXX             != command -v c++
CPP             := $(CC) -E
PATH            := /usr/bin:$(PATH)

CFLAGS_FOR_BUILD   := -arch $(shell arch) -mappletvos-version-min=$(shell sw_vers -productVersion)
CPPFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
CXXFLAGS_FOR_BUILD := $(CFLAGS_FOR_BUILD)
ASFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)
LDFLAGS_FOR_BUILD  := $(CFLAGS_FOR_BUILD)

endif # ifeq ($(shell sw_vers -productName),macOS)
AR              != command -v ar
LD              != command -v ld
RANLIB          != command -v ranlib
STRINGS         != command -v strings
STRIP           != command -v strip
NM              != command -v nm
LIPO            != command -v lipo
OTOOL           != command -v otool
I_N_T           != command -v install_name_tool
LIBTOOL         != command -v libtool

else
$(error Please use macOS, iOS, tvOS, Linux, or FreeBSD to build)
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

LDID := ldid -Hsha256 -Cadhoc $(MEMO_LDID_EXTRA_FLAGS)

REPO_BASE      != dirname $(realpath $(firstword $(MAKEFILE_LIST)))
# Root
BUILD_ROOT     ?= $(PWD)
# Downloaded source files
BUILD_SOURCE   := $(BUILD_ROOT)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     := $(BUILD_ROOT)/build_base/$(MEMO_TARGET)/$(MEMO_CFVER)
# Dpkg info storage area
BUILD_INFO     ?= $(REPO_BASE)/build_info
# Miscellaneous Procursus files
BUILD_MISC     ?= $(REPO_BASE)/build_misc
# Patch storage area
BUILD_PATCH    ?= $(REPO_BASE)/build_patch
# Extracted source working directory
BUILD_WORK     := $(BUILD_ROOT)/build_work/$(MEMO_TARGET)/$(MEMO_CFVER)
# Bootstrap working area
BUILD_STAGE    := $(BUILD_ROOT)/build_stage/$(MEMO_TARGET)/$(MEMO_CFVER)
# Final output
BUILD_DIST     := $(BUILD_ROOT)/build_dist/$(MEMO_TARGET)/$(MEMO_CFVER)/work/
# Actual bootrap staging
BUILD_STRAP    := $(BUILD_ROOT)/build_strap/$(MEMO_TARGET)/$(MEMO_CFVER)
# Extra scripts for the buildsystem
BUILD_TOOLS    ?= $(REPO_BASE)/build_tools

ifeq ($(DEBUG),1)
OPTIMIZATION_FLAGS := -g -O0
else ifeq ($(MEMO_TARGET),bridgeos-arm64)
OPTIMIZATION_FLAGS := -Oz
else
ifeq ($(BINPACK),1)
OPTIMIZATION_FLAGS := -Oz
else
OPTIMIZATION_FLAGS := -Os
endif
ifneq ($(DEBUG),1)
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
endif
ifdef ($(MEMO_ALT_LTO_LIB))
OPTIMIZATION_FLAGS += -lto_library $(MEMO_ALT_LTO_LIB)
endif

CFLAGS              := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem$(TARGET_SYSROOT)/usr/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
ASFLAGS             := $(CFLAGS)
CPPFLAGS            := -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem$(TARGET_SYSROOT)/usr/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include
LDFLAGS             := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks -Wl,-not_for_dyld_shared_cache
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
CXXFLAGS            += -DLIBIOSEXEC_INTERNAL
CPPFLAGS            += -DLIBIOSEXEC_INTERNAL
endif
endif

MEMO_MANPAGE_COMPRESSION := zstd

ifeq ($(MEMO_MANPAGE_COMPRESSION),zstd)
MEMO_MANPAGE_SUFFIX   := .zst
MEMO_MANPAGE_COMPCMD  := zstd
MEMO_MANPAGE_COMPFLGS += -f19 --rm

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

ifeq ($(DEBUG),1)
MEMO_CMAKE_BUILD_TYPE = Debug
else
MEMO_CMAKE_BUILD_TYPE = Release
endif

DEFAULT_CMAKE_FLAGS := \
	-DCMAKE_BUILD_TYPE=$(MEMO_CMAKE_BUILD_TYPE) \
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
	ASFLAGS="$(ASFLAGS_FOR_BUILD)" \
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
	INSTALLSITEARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	INSTALLARCHLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	INSTALLVENDORARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	INSTALLPRIVLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	INSTALLSITELIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	INSTALLVENDORLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	PERL_LIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	PERL_ARCHLIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	PERL_ARCHLIBDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	PERL_INC=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR}/CORE \
	PERL_INCDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR}/CORE \
	PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	INSTALLMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLSITEMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLVENDORMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	INSTALLMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	INSTALLSITEMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	INSTALLVENDORMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	PERL="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl" \
	PERLRUN="$(shell which perl)" \
	FULLPERLRUN="$(shell which perl)" \
	ABSPERLRUN="$(shell which perl)" \
	CCFLAGS="$(CFLAGS)" \
	LDDLFLAGS="$(LDFLAGS) -shared"

DEFAULT_PERL_BUILD_FLAGS := \
	cc=$(CC) \
	ld=$(CC) \
	install_base=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	install_path=lib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	install_path=arch=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
	install_path=bin=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	install_path=script=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	install_path=libdoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
	install_path=bindoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
	install_path=html=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/perl5

DEFAULT_GOLANG_FLAGS := \
	GOOS=$(GOLANG_OS) \
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
	$(MEMO_DEPLOYMENT) \
	SDKROOT="$(TARGET_SYSROOT)" \
	PKG_CONFIG="$(RUST_TARGET)-pkg-config" \
	RUSTFLAGS="-L $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib"

export PLATFORM MEMO_ARCH TARGET_SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE MEMO_PREFIX MEMO_SUB_PREFIX MEMO_ALT_PREFIX
export CC CXX AR LD CPP RANLIB STRIP NM LIPO OTOOL I_N_T INSTALL
export BUILD_ROOT BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS ASFLAGS LDFLAGS ACLOCAL_PATH PKG_CONFIG_PATH
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

###
#
# TODO: Account for multiple files being hashed in the shafile (xz, xz.asc, etc)
#
###

CHECKSUM_VERIFY = if [ "$(1)" = "sha1" -o "$(1)" = "sha1sum" ]; then \
			HASH=$$(sha1sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		elif [ "$(1)" = "sha256" -o "$(1)" = "sha256sum" ]; then \
			HASH=$$(sha256sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		elif [ "$(1)" = "sha512" -o "$(1)" = "sha512sum" ]; then \
			HASH=$$(sha512sum "$(BUILD_SOURCE)/$(2)" | cut -d " " -f1 | tr -d \n); \
		fi; \
		if [ "$(3)" = "" ]; then \
			[ "$$(head -n1 "$(BUILD_SOURCE)/$(2).$(1)" | cut -d" " -f1)" = "$$HASH" ] || (echo "$(2) - Invalid Hash" && exit 1); \
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

DOWNLOAD_FILE = if [ ! -f "$(1)" ]; then \
					echo "Downloading $(1)"; \
					if [ -z "$$LIST" ]; then \
						$(CURL) --output \
							$(1) $(2) ; \
					else \
						$(CURL) --output \
							$(1) $(2) & \
					fi; \
				else echo "$(1) already downloaded."; fi

DOWNLOAD_FILES = LIST="$$(echo $(2))"; \
				for url in $$LIST; do \
					file=$${url\#\#*/}; \
					$(call DOWNLOAD_FILE,$(1)/$$file,$$url); \
				done; wait

DO_PATCH    = cd $(BUILD_PATCH)/$(1); \
	for PATCHFILE in *; do \
		if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done ]; then \
			sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' -e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' $$PATCHFILE | patch -sN -d $(BUILD_WORK)/$(2) $(3) && \
			touch $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done; \
		fi; \
	done

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SIGN = 	for file in $$(find $(BUILD_DIST)/$(1) -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
			if [ $${file\#\#*.} != "a" ]; then \
				if [ $${file\#\#*.} = "dylib" ] || [ $${file\#\#*.} = "bundle" ] || [ $${file\#\#*.} = "so" ]; then \
					$(LDID) -S $$file; \
				else \
					$(LDID) -S$(BUILD_MISC)/entitlements/$(2) $$file; \
					if [ "$(2)" != "general.xml" ] && [ "$(5)" != "nogeneral" ]; then \
						$(LDID) -M -S$(BUILD_MISC)/entitlements/general.xml $$file; \
					fi; \
				fi; \
			fi; \
		done
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
			if [ $${file\#\#*.} != "a" ] && [ $${file\#\#*.} != "dSYM" ]; then \
				INSTALL_NAME=$$($(OTOOL) -D $$file | grep -v -e ":$$" -e "^Archive :" | head -n1); \
				if [ ! -z "$$INSTALL_NAME" ]; then \
					$(I_N_T) -id @rpath/$$(basename $$INSTALL_NAME) $$file; \
					echo "$$INSTALL_NAME" >> $(BUILD_STAGE)/$$pkg/._lib_cache; \
				fi; \
			fi; \
		done; \
	fi; \
	for file in $$(find $(BUILD_STAGE)/$$pkg -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
		if [ $${file\#\#*.} != "a" ] && [ $${file\#\#*.} != "dSYM" ]; then \
			if [ "$(RELATIVE_RPATH)" = "1" ]; then \
				$(I_N_T) -add_rpath "@loader_path/$$(realpath --relative-to=$$(dirname $$file) $(BUILD_STAGE)/$$pkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX))/lib" $$file; \
			else \
				$(I_N_T) -add_rpath "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" $$file; \
				if [ ! -z "$(3)" ]; then \
					$(I_N_T) -add_rpath "$(3)" $$file; \
				fi; \
			fi; \
			if [ -f $(BUILD_STAGE)/$$pkg/._lib_cache ]; then \
				cat $(BUILD_STAGE)/$$pkg/._lib_cache | while read line; do \
					$(I_N_T) -change $$line @rpath/$$(basename $$line) $$file; \
				done; \
			fi; \
			if [ "$(DEBUG)" != "1" ]; then $(STRIP) -x $$file; fi \
		fi; \
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
	find $(BUILD_BASE) -name '*.la' \( -type f -o -type l \) -delete

PACK = \
	if [ -z "$(4)" ]; then \
		find $(BUILD_DIST)/$(1) -name '*.la' \( -type f -o -type l \) -delete; \
	fi; \
	rm -f $(BUILD_DIST)/$(1)/.build_complete; \
	rm -rf $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{info,doc}; \
	for file in AUTHORS{,.TXT} COPYING{,.TXT} LICENSE{,.TXT} NEWS{,.TXT} README{,.TXT} THANKS{,.TXT} TODO{,.TXT}; do \
		if [ -f "$(BUILD_WORK)/$$(echo $@ | sed 's/-package//')/$$file" ]; then \
			mkdir -p $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1); \
			cp -aL $(BUILD_WORK)/$$(echo $@ | sed 's/-package//')/$$file $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1); \
			if [ "$(MEMO_NO_DOC_COMPRESS)" != 1 ]; then \
				if [ ! "$$file" = "AUTHORS" ] && [ ! "$$file" = "COPYING" ] && [ ! "$$file" = "LICENSE" ]; then \
					zstd -f19 --rm $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$(1)/$$file 2> /dev/null; \
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
	if ! grep -q "darwin" <<< "$(MEMO_TARGET)"; then \
		if ! [ "$(1)" = "libiosexec1" ] || ! [ "$(1)" = "libiosexec-dev" ]; then \
			if find $(BUILD_DIST)/$(1) | xargs file -ib | grep 'x-mach-binary' | head -1 | grep -q 'x-mach-binary'; then \
				if grep -q '^Depends\:' $(BUILD_DIST)/$(1)/DEBIAN/control; then \
					sed -i 's/^Depends\:/Depends: libiosexec1 (>= '$${DEB_LIBIOSEXEC_V}'),/' $(BUILD_DIST)/$(1)/DEBIAN/control; \
				else \
					echo 'Depends: libiosexec1 (>= '$${DEB_LIBIOSEXEC_V}')' >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
				fi; \
			fi; \
		fi; \
	fi; \
	find $(BUILD_DIST)/$(1)/$(MEMO_PREFIX)/etc -type f -printf '$(MEMO_PREFIX)/etc/%P\n' | LC_ALL=C sort >> $(BUILD_DIST)/$(1)/DEBIAN/conffiles; \
	[ -s $(BUILD_DIST)/$(1)/DEBIAN/conffiles ] || rm $(BUILD_DIST)/$(1)/DEBIAN/conffiles; \
	sed -i '$$a\' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	cd $(BUILD_DIST)/$(1) && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '"%P" ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	if [ ! "$(MEMO_QUIET)" == "1" ]; then \
	echo "Installed-Size: $$SIZE"; \
	fi; \
	echo "Installed-Size: $$SIZE" >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
	find $(BUILD_DIST)/$(1) -name '.DS_Store' -type f -delete; \
	mkdir -p $(BUILD_DIST)/../$$(echo $@ | sed 's/-package//'); \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/../$$(echo $@ | sed 's/-package//')/$$(grep Package: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ')_$($(2))_$$(grep Architecture: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ').deb

GITHUB_ARCHIVE = -if [ "x$(5)" != "x" ]; then \
					[ ! -f "$(BUILD_SOURCE)/$(5)-$(3).tar.gz" ] && \
						$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/$(5)-$(3).tar.gz, \
							https://github.com/$(1)/$(2)/archive/$(4).tar.gz); \
				else \
					[ ! -f "$(BUILD_SOURCE)/$(2)-$(3).tar.gz" ] && \
						$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/$(2)-$(3).tar.gz, \
							https://github.com/$(1)/$(2)/archive/$(4).tar.gz); \
				fi

GIT_CLONE = if [ ! -d "$(BUILD_WORK)/$(3)" ]; then \
				git clone -c advice.detachedHead=false --depth 1 --branch "$(2)" --recursive "$(1)" "$(BUILD_WORK)/$(3)"; \
			fi

###
#
# Fix this dep checking section dumbass
#
###

ifneq ($(call HAS_COMMAND,curl),1)
$(error Install curl)
else
CURL := curl --silent -L --create-dirs
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
ifeq ($(DEBUG),1)
export INSTALL := $(shell PATH="$(PATH)" which install)
else
export INSTALL := $(shell PATH="$(PATH)" which install) --strip-program=$(STRIP)
endif
export LN_S    := ln -sf
export LN_SR   := ln -sfr
else
$(error Install GNU coreutils)
endif

ifeq ($(shell sw_vers -productName),macOS)
ifneq  ($(shell PATH="$(PATH)" file -bi /bin/sh | grep -q 'x-mach-binary; charset=binary' && echo 1),1)
$(error Install better file from Procursus - sudo apt install file)
endif
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
MAKEFLAGS += --jobs=$(CORE_COUNT)
endif

PROCURSUS := 1

all:: help

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
	for DEB in $$(find $(BUILD_DIST)/../ -name "*.deb"); do \
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

strapprojects:: export BUILD_DIST=$(BUILD_STRAP)/work/
strapprojects:: $(STRAPPROJECTS:%=%-package)
bootstrap:: .SHELLFLAGS=-O extglob -c
bootstrap:: strapprojects
	mkdir -p $(BUILD_DIST)
	cp -a $(BUILD_STRAP)/* $(BUILD_DIST)
	rm -rf $(BUILD_STRAP)/strap
	rm -f $(BUILD_STAGE)/.fakeroot_bootstrap
	touch $(BUILD_STAGE)/.fakeroot_bootstrap
	mkdir -p $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/info
	touch $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/Library/dpkg/{status,available}
	-if echo $(MEMO_TARGET) | grep "darwin"; then \
		PKGS="apt/apt_*.deb brotli/libbrotli1_*.deb cacerts/ca-certificates_*.deb coreutils/coreutils_*.deb darwintools/darwintools_*.deb dpkg/dpkg_*.deb gnupg/gpgv_*.deb apt/libapt-pkg6.0_*.deb libassuan/libassuan0_*.deb libffi/libffi8_*.deb libgcrypt/libgcrypt20_*.deb libgmp10/libgmp10_*.deb gnutls/libgnutls30_*.deb libgpg-error/libgpg-error0_*.deb nettle/libhogweed6_*.deb libidn2/libidn2-0_*.deb gettext/libintl8_*.deb lz4/liblz4-1_*.deb xz/liblzma5_*.deb libmd/libmd0_*.deb nettle/libnettle8_*.deb npth/libnpth0_*.deb p11-kit/libp11-kit0_*.deb openssl/libssl3_*.deb libtasn1/libtasn1-6_*.deb libunistring/libunistring5_*.deb xxhash/libxxhash0_*.deb zlib-ng/libz-ng2_*.deb zstd/libzstd1_*.deb keyring/procursus-keyring_*.deb tar/tar_*.deb"; \
	else \
		PKGS="apt/apt_*.deb base/base_*.deb bash/bash_*.deb brotli/libbrotli1_*.deb cacerts/ca-certificates_*.deb chariz-keyring/chariz-keyring_*.deb coreutils/coreutils_*.deb darwintools/darwintools_*.deb dash/dash_*.deb debianutils/debianutils_*.deb diffutils/diffutils_*.deb diskdev-cmds/diskdev-cmds_*.deb dpkg/dpkg_*.deb essential/essential_*.deb file-cmds/file-cmds_*.deb findutils/findutils_*.deb firmware-sbin/firmware-sbin_*.deb gnupg/gpgv_*.deb grep/grep_*.deb havoc-keyring/havoc-keyring_*.deb launchctl/launchctl_*.deb apt/libapt-pkg6.0_*.deb libassuan/libassuan0_*.deb libxcrypt/libcrypt2_*.deb dimentio/libdimentio0_*.deb libedit/libedit0_*.deb libffi/libffi8_*.deb libgcrypt/libgcrypt20_*.deb libgmp10/libgmp10_*.deb gnutls/libgnutls30_*.deb libgpg-error/libgpg-error0_*.deb nettle/libhogweed6_*.deb libidn2/libidn2-0_*.deb gettext/libintl8_*.deb libiosexec/libiosexec1_*.deb libkrw/libkrw0_*.deb lz4/liblz4-1_*.deb xz/liblzma5_*.deb libmd/libmd0_*.deb ncurses/libncursesw6_*.deb nettle/libnettle8_*.deb npth/libnpth0_*.deb p11-kit/libp11-kit0_*.deb pam-modules/libpam-modules_*.deb openpam/libpam2_*.deb pcre/libpcre1_*.deb pcre2/libpcre2-8-0_*.deb readline/libreadline8_*.deb libtasn1/libtasn1-6_*.deb libunistring/libunistring5_*.deb xxhash/libxxhash0_*.deb zlib-ng/libz-ng2_*.deb zstd/libzstd1_*.deb ncurses/ncurses-bin_*.deb ncurses/ncurses-term_*.deb openssh/openssh-server_*.deb openssh/openssh-sftp-server_*.deb openssh/openssh-client_*.deb openssl/libssl3_*.deb keyring/procursus-keyring_*.deb profile.d/profile.d_*.deb sed/sed_*.deb shell-cmds/shell-cmds_*.deb shshd/shshd_*.deb snaputil/snaputil_*.deb sudo/sudo_*.deb system-cmds/system-cmds_*.deb tar/tar_*.deb uikittools/uikittools_*.deb vi/vi_*.deb zsh/zsh_*.deb"; \
	fi; \
	cd $(BUILD_STRAP); for DEB in $$PKGS; do \
		if [ ! -f $$DEB ]; then \
			continue; \
		fi; \
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
ifeq ($(shell grep -q 'rootless' <<< '$(MEMO_TARGET)' && echo 1),1)
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
else
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MEMO_TARGET)/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/private/etc/apt/sources.list.d/procursus.sources
endif
	if [[ "$(SSH_STRAP)" = 1 ]]; then \
		sed -e 's/@SSH_STRAP@//' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	else \
		sed -e '/@SSH_STRAP@/d' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	fi; \
	chmod +x $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
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
	LANG="$(SAVED_LANG)" gpg --armor -u $(MEMO_PGP_SIGN_KEY) --detach-sign $(BUILD_STRAP)/$${BOOTSTRAP}; \
	rm -rf $(BUILD_STRAP)/*/; \
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
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1800 ] && echo 1),1)
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
else
	echo -e "Types: deb\n\
URIs: $(MEMO_REPO_URI)/\n\
Suites: $(MEMO_TARGET)/$(MEMO_CFVER)\n\
Components: main\n" > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/etc/apt/sources.list.d/procursus.sources
endif
	if [[ "$(SSH_STRAP)" = 1 ]]; then \
		sed -e 's/@SSH_STRAP@//' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	else \
		sed -e '/@SSH_STRAP@/d' -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/prep_bootstrap.sh > $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	fi
	if [ ! -z "$(findstring rootless,$(MEMO_TARGET))" ]; then \
		sed -i -e 's/@ROOTLESS@//' $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	else \
		sed -i -e '/@ROOTLESS@/d' $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh; \
	fi
	chmod +x $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/prep_bootstrap.sh
endif
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
	$$FAKEROOT chown 0:0 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/var/root; \
	$$FAKEROOT chown 501:501 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/var/mobile; \
	$$FAKEROOT chmod 1777 $(BUILD_STRAP)/strap/$(MEMO_PREFIX)/tmp; \
	cd $(BUILD_STRAP)/strap && $$FAKEROOT tar -cf ../bootstrap.tar .
	@if [[ "$(SSH_STRAP)" = 1 ]]; then \
		BOOTSTRAP=bootstrap-ssh.tar.zst; \
	else \
		BOOTSTRAP=bootstrap.tar.zst; \
	fi; \
	zstd -qf -c19 --rm $(BUILD_STRAP)/bootstrap.tar > $(BUILD_STRAP)/$${BOOTSTRAP}; \
	gpg --armor -u $(MEMO_PGP_SIGN_KEY) --detach-sign $(BUILD_STRAP)/$${BOOTSTRAP}; \
	rm -rf $(BUILD_STRAP)/*/; \
	echo "********** Successfully built bootstrap with **********"; \
	echo "$(STRAPPROJECTS)"; \
	echo "$(BUILD_STRAP)/$${BOOTSTRAP}"
endif # ($(MEMO_PREFIX),)

%-package: FAKEROOT=fakeroot -i $(BUILD_STAGE)/.fakeroot_$$(echo $@ | sed 's/\(.*\)-package/\1/') -s $(BUILD_STAGE)/.fakeroot_$$(echo $@ | sed 's/\(.*\)-package/\1/') --
%-package: .SHELLFLAGS=-O extglob -c
%-stage: %
	mkdir -p $(BUILD_DIST) $(BUILD_STAGE)
	rm -f $(BUILD_STAGE)/.fakeroot_$*
	touch $(BUILD_STAGE)/.fakeroot_$*

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
		$(BUILD_BASE) $(BUILD_BASE)$(MEMO_PREFIX)/{{,System}/Library/Frameworks,$(MEMO_SUB_PREFIX)/{include/{bsm,objc,os/internal,sys,firehose,CoreFoundation,FSEvents,IOKit/kext,libkern,kern,arm,{mach/,}machine,CommonCrypto,corecrypto,Security,CoreSymbolication,Kernel/{kern,IOKit,libkern},rpc,rpcsvc,xpc/private,ktrace,mach-o,dispatch},lib/pkgconfig,$(MEMO_ALT_PREFIX)/lib}} \
		$(BUILD_SOURCE) $(BUILD_WORK) $(BUILD_STAGE) $(BUILD_STRAP)

	@rm -rf $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/System
	@$(LN_SR) $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include{,/System}

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libsyscall/wrappers/{spawn/spawn{$(comma)_private}$(comma)libproc/libproc{$(comma)_internal$(comma)_private}}.h \
		https://github.com/apple-oss-distributions/launchd/raw/launchd-842.92.1/liblaunch/{bootstrap$(comma)vproc}_priv.h \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-306.0.1/private/_simple.h \
		https://github.com/apple-oss-distributions/libutil/raw/libutil-70.1.1/{mntopts$(comma)libutil}.h \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/{EXTERNAL_HEADERS/mach-o/nlist$(comma)osfmk/mach/vm_statistics}.h \
		https://github.com/apple-oss-distributions/libmalloc/raw/libmalloc-474.0.13/private/stack_logging.h \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1583.0.14/{gen/get_compat$(comma)include/struct}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach-o, \
		https://github.com/apple-oss-distributions/dyld/raw/dyld-1122.1/{include/mach-o/dyld_{process_info$(comma)introspection}$(comma)cache-builder/dyld_cache_format}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/kern, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/osfmk/kern/ledger.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/IOKit, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/iokit/IOKit/IOKitDebug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Kernel/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/libkern/OSKextLibPrivate.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/kern,https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/osfmk/kern/debug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/arm, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/{bsd/arm/disklabel$(comma)osfmk/arm/cpu_capabilities}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/bsd/machine/disklabel.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os, \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1583.0.14/os/assumes.h \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/os/{base_private$(comma)log_private$(comma)log}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CommonCrypto, \
		https://github.com/apple-oss-distributions/CommonCrypto/raw/CommonCrypto-600025/include/Private/CommonDigestSPI.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/bsm, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/bsd/bsm/audit_kevents.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/kext, \
		https://github.com/apple-oss-distributions/IOKitUser/raw/IOKitUser-100065.1.1/kext.subproj/{KextManagerPriv$(comma)OSKext$(comma)OSKextPrivate$(comma)kextmanager_types$(comma){fat$(comma)macho$(comma)misc}_util}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security, \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/OSX/libsecurity_keychain/lib/SecKeychainPriv.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/OSX/libsecurity_codesigning/lib/Sec{CodeSigner$(comma){Code$(comma)Requirement}Priv}.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/base/SecBasePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation, \
		https://github.com/apple-oss-distributions/CF/raw/CF-1153.18/CFBundlePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/osfmk/machine/cpu_capabilities.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/firehose/{tracepoint$(comma)firehose_types}_private.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9//libkern/libkern/{OSKextLibPrivate$(comma)mkext$(comma)prelink}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/internal, \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-126.50.8/include/os/internal/{internal_shared$(comma)atomic$(comma)crashlog}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/bsd/sys/{fcntl$(comma)fsctl$(comma)spawn_internal$(comma)resource$(comma)event$(comma)event_private$(comma)kdebug$(comma)kdebug_private$(comma)proc$(comma)proc_info$(comma)proc_info_private$(comma)pgo$(comma)proc_uuid_policy$(comma)acct$(comma)stackshot$(comma)event$(comma)mbuf$(comma)kern_memorystatus$(comma)reason}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/uuid, \
		https://github.com/apple-oss-distributions/Libc/raw/Libc-1583.0.14/uuid/namespace.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/osfmk/mach/coalition.h)

	@# FSEvents headers won't be found even when building for macOS... Should probably fix this properly eventually
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreServices.framework/Frameworks/FSEvents.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/FSEvents/

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/iokit/IOKit/IOKitDebug.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/kext, \
		https://github.com/apple-oss-distributions/IOKitUser/raw/IOKitUser-100065.1.1/kext.subproj/{KextManagerPriv$(comma)OSKext$(comma)OSKextPrivate$(comma)kextmanager_types$(comma){fat$(comma)macho$(comma)misc}_util}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security, \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/OSX/libsecurity_keychain/lib/SecKeychainPriv.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/OSX/libsecurity_codesigning/lib/Sec{CodeSigner$(comma){Code$(comma)Requirement}Priv}.h \
		https://github.com/apple-oss-distributions/Security/raw/Security-61040.1.3/base/SecBasePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation, \
		https://github.com/apple-oss-distributions/CF/raw/CF-1153.18/CFBundlePriv.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/machine, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/osfmk/machine/cpu_capabilities.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/firehose/tracepoint_private.h \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/firehose/firehose_types_private.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/libkern/libkern/{OSKextLibPrivate$(comma)mkext$(comma)prelink}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/internal, \
		https://github.com/apple-oss-distributions/libplatform/raw/libplatform-126.50.8/include/os/internal/{internal_shared$(comma)atomic$(comma)crashlog}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/bsd/sys/{fcntl$(comma)fsctl$(comma)spawn_internal$(comma)resource$(comma)event$(comma)kdebug$(comma)proc$(comma)proc_info$(comma)pgo$(comma)proc_uuid_policy$(comma)acct$(comma)stackshot$(comma)event$(comma)mbuf$(comma)kern_memorystatus$(comma)reason}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpc, \
		https://github.com/Torrekie/apple_internal_sdk/raw/322eb6573bc701e7f35af05650b0cc162d0355c1/usr/include/xpc/private.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ktrace, \
		https://github.com/Torrekie/apple_internal_sdk/raw/fa5457b4e5246d20da5a74f1449b37dfd79f1248/usr/include/ktrace/{private$(comma)session}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/perfdata, \
		https://github.com/Torrekie/apple_internal_sdk/raw/757ad82d5a680005bd253447dd3842217c6c8abc/usr/include/perfdata/perfdata.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreSymbolication, \
		https://github.com/Torrekie/apple_internal_sdk/raw/fa5457b4e5246d20da5a74f1449b37dfd79f1248/System/Library/PrivateFrameworks/CoreSymbolication.framework/Headers/CoreSymbolication{$(comma)Private}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/dispatch, \
		https://github.com/apple-oss-distributions/libdispatch/raw/libdispatch-1462.0.4/private/{private$(comma)benchmark$(comma){apply$(comma)channel$(comma)data$(comma)introspection$(comma)io$(comma)layout$(comma)mach$(comma)queue$(comma)source$(comma)time$(comma)workloop}_private}.h)

	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/corecrypto, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10063.121.3/EXTERNAL_HEADERS/corecrypto/cc{$(comma)digest$(comma)n$(comma)_config$(comma)_impl$(comma)_error$(comma)sha1$(comma)sha2}.h)

	@cp -a $(BUILD_MISC)/{libxml-2.0,zlib}.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && echo 1),1)
	@cp -a $(BUILD_MISC)/expat.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
endif

ifeq ($(UNAME),FreeBSD)
	@# FreeBSD's LLVM does not have stdbool.h, stdatomic.h, and stdarg.h
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool,stdatomic,stdarg}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af /usr/include/stdalign.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	@$(call DOWNLOAD_FILES,$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-10002.41.9/bsd/sys/resource.h \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8020.140.41/bsd/sys/vnioctl.h)
	rm -f $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/utmp.h

	@# Copy headers from MacOSX.sdk
	@cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,xpc,protocols,netinet,netinet6,servers,timeconv.h,launch.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/objc
	@cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkern
	@cp -af $(MACOSX_SYSROOT)/usr/include/kern $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,ptrace,sys_domain,kern*,random,reboot,user,vnode,disk,vmmeter,conf}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af  $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sys
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecDigestTransform,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,SecReadTransform,oids,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,SecEncryptTransform,cssmapi,cssmcli,mds,x509defs,oidsbase,SecSignVerifyTransform,cssmspi,cssmkrspi,SecTask,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,SecCustomTransform,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTransform,SecTrustSettings,SecStaticCode,emmspi,SecTransformReadTransform,SecKeychain,SecDecodeTransform,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecEncodeTransform,SecureDownload,SecAsn1Templates,AuthorizationDB,SecCertificateOIDs,cssmapple}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security
	@cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,nlist,NSSystemDirectories,tzfile,vproc}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(MACOSX_SYSROOT)/usr/include/rpc/pmap_clnt.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rpc
	@cp -af $(MACOSX_SYSROOT)/usr/include/rpcsvc/yp{_prot,clnt}.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/rpcsvc
	@cp -af $(MACOSX_SYSROOT)/usr/include/mach-o/{i386,x86_64,arm} $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach-o
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/machine
	@cp -af $(TARGET_SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach
	@cp -af $(BUILD_INFO)/availability.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os
ifneq ($(wildcard $(BUILD_MISC)/IOKit.framework.$(PLATFORM)),)
	@cp -af $(BUILD_MISC)/IOKit.framework.$(PLATFORM) $(BUILD_BASE)/$(MEMO_PREFIX)/System/Library/Frameworks/IOKit.framework
endif

	@mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{CoreAudio,CoreFoundation}
	@cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/CoreAudio.framework/Headers/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreAudio

	@# Patch headers from $(BARE_PLATFORM).sdk
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h ]; then sed -E 's/API_UNAVAILABLE(ios, watchos, tvos)//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/CoreFoundation/CFUserNotification.h; fi
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/time.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/task.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/spawn.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/spawn.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/mach_host.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/thread_act.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/thread_act.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/message.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/message.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ucontext.h
	@sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/signal.h
	@if [ -f $(TARGET_SYSROOT)/usr/include/_stdlib.h ]; then sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/_stdlib.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/_stdlib.h; fi
	@if [ -f $(TARGET_SYSROOT)/usr/include/_time.h ]; then sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/_time.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/_time.h; fi
	@sed -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pthread.h
	@sed -i 's/__API_UNAVAILABLE(.*)//g' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/spawn.h
	@sed -i -E s/'__API_UNAVAILABLE\(.*\)'// $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit/IOKitLib.h
	@sed -E -e '\|/var/tmp|! s|"/var|"$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/pwd.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pwd.h
	@sed -E -e '\|/var/tmp|! s|"/var|"$(MEMO_PREFIX)/var|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/grp.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/grp.h
	@sed -E -e 's|"/var|"$(MEMO_PREFIX)/var|g' -e 's|"/tmp|"$(MEMO_PREFIX)/tmp|g' -e '\|/bin:|! s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e '\|/bin:|! s|"/bin|"$(MEMO_PREFIX)/bin|g' -e '\|/bin:|! s|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/usr/bin:|$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin:/usr/bin:|g' -e 's|/usr/sbin:|$(MEMO_PREFIX)/sbin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin:/usr/sbin:|g' < $(TARGET_SYSROOT)/usr/include/paths.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/paths.h

	@#Patch downloaded headers
	@sed -i '1s|^|#include <Security/cssmapi.h>\n#include <Security/SecKeychain.h>\n|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecKeychainPriv.h
	@sed -i '1s|^|#include <arm/cpu_capabilities.h>\n|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/firehose/tracepoint_private.h
	@sed -i -e 's/__osloglike([0-9], [0-9])//' -e 's|extern void \*__dso_handle;|#ifndef __OS_TRACE_BASE_H__\nextern struct mach_header __dso_handle;\n#endif|' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/log{,_private}.h
	@sed -i 's/, ios(NA), bridgeos(NA)//' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Security/SecBasePriv.h
	@sed -i 's/__API_UNAVAILABLE(ios, tvos, watchos) __API_UNAVAILABLE(bridgeos)//' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach-o/dyld_process_info.h
	@sed 's/#ifndef __OPEN_SOURCE__/#if 1\n#if defined(__has_feature) \&\& defined(__has_attribute)\n#if __has_attribute(availability)\n#define __API_AVAILABLE_PLATFORM_bridgeos(x) bridgeos,introduced=x\n#define __API_DEPRECATED_PLATFORM_bridgeos(x,y) bridgeos,introduced=x,deprecated=y\n#define __API_UNAVAILABLE_PLATFORM_bridgeos bridgeos,unavailable\n#endif\n#endif/g' < $(TARGET_SYSROOT)/usr/include/AvailabilityInternal.h > $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/AvailabilityInternal.h

	@# Setup libiosexec
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	@cp -af $(BUILD_MISC)/libiosexec/libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.1.tbd
	@$(LN_S) libiosexec.1.tbd $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.tbd
	@rm -f $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.*.dylib
ifneq ($(MEMO_NO_IOSEXEC),1)
	@sed -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{unistd,pwd,grp}.h
	@grep -q libiosexec.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/spawn.h || sed -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/spawn.h
endif
endif

ifneq ($(MEMO_QUIET),1)
	@echo Makeflags: $(MAKEFLAGS)
	@echo Path: $(PATH)
endif # ($(MEMO_QUIET),1)

clean::
	rm -rf $(BUILD_ROOT)/build_{source,stage}

extreme-clean: clean
	rm -rf $(BUILD_ROOT)/build_{base,strap,work}

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
$(MAKE)                        - Display this text
$(MAKE) (tool)                 - Used to compile only a specified tool.
$(MAKE) (tool)-package         - Used to compile only a specified tool and pack it into a debian package.
$(MAKE) rebuild-(tool)         - Used to recompile only a specified tool after it's already been compiled before.
$(MAKE) rebuild-(tool)-package - Used to recompile only a specified tool after it's already been compiled before and pack it into a debian package.
$(MAKE) clean                  - Clean out $(BUILD_STAGE), $(BUILD_BASE), and $(BUILD_WORK).
$(MAKE) extreme-clean          - Runs `$(MAKE) clean`and cleans out $(BUILD_DIST).
$(MAKE) package                - Compiles the entire Procursus suite and packs it into debian packages.
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
