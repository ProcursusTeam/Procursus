ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Procursus - sudo apt install make)
endif

# Comma var must be here because makefile functions cannot contain commas
comma := ,

export LANG := C

ifeq ($(shell LANG=C /usr/bin/env bash --version | grep -iq 'version 5' && echo 1),1)
SHELL := /usr/bin/env bash
else
$(error Install bash 5.0)
endif

# Unset sysroot, we manage that ourselves.
SYSROOT :=

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

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && [ "$(CFVER_WHOLE)" -lt 2100 ] && echo 1),1)
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
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && [ "$(CFVER_WHOLE)" -lt 1500 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 11.0
APPLETVOS_DEPLOYMENT_TARGET := 11.0
AUDIOOS_DEPLOYMENT_TARGET   := 11.0
BRIDGEOS_DEPLOYMENT_TARGET  := 2.0
WATCHOS_DEPLOYMENT_TARGET   := 4.0
MACOSX_DEPLOYMENT_TARGET    := 10.13
DARWIN_DEPLOYMENT_VERSION   := 17
override MEMO_CFVER         := 1400
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1300 ] && [ "$(CFVER_WHOLE)" -lt 1400 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 10.0
APPLETVOS_DEPLOYMENT_TARGET := 10.0
AUDIOOS_DEPLOYMENT_TARGET   := 10.0
BRIDGEOS_DEPLOYMENT_TARGET  := 1.0
WATCHOS_DEPLOYMENT_TARGET   := 3.0
MACOSX_DEPLOYMENT_TARGET    := 10.12
DARWIN_DEPLOYMENT_VERSION   := 16
override MEMO_CFVER         := 1300
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1200 ] && [ "$(CFVER_WHOLE)" -lt 1300 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 9.0
APPLETVOS_DEPLOYMENT_TARGET := 9.0
AUDIOOS_DEPLOYMENT_TARGET   := 9.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 2.0
MACOSX_DEPLOYMENT_TARGET    := 10.11
DARWIN_DEPLOYMENT_VERSION   := 15
override MEMO_CFVER         := 1200
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1100 ] && [ "$(CFVER_WHOLE)" -lt 1200 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 8.0
APPLETVOS_DEPLOYMENT_TARGET := 8.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 1.0
MACOSX_DEPLOYMENT_TARGET    := 10.10
DARWIN_DEPLOYMENT_VERSION   := 14
override MEMO_CFVER         := 1100
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1000 ] && [ "$(CFVER_WHOLE)" -lt 1100 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 7.0
APPLETVOS_DEPLOYMENT_TARGET := 7.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.9
DARWIN_DEPLOYMENT_VERSION   := 14
override MEMO_CFVER         := 1000
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 900 ] && [ "$(CFVER_WHOLE)" -lt 1000 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 6.0
APPLETVOS_DEPLOYMENT_TARGET := 6.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.8
DARWIN_DEPLOYMENT_VERSION   := 13
override MEMO_CFVER         := 900
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && [ "$(CFVER_WHOLE)" -lt 900 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 5.0
APPLETVOS_DEPLOYMENT_TARGET := 5.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.7
DARWIN_DEPLOYMENT_VERSION   := 11
override MEMO_CFVER         := 800
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 700 ] && [ "$(CFVER_WHOLE)" -lt 800 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 4.0
APPLETVOS_DEPLOYMENT_TARGET := 4.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.6
DARWIN_DEPLOYMENT_VERSION   := 10
override MEMO_CFVER         := 700
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 600 ] && [ "$(CFVER_WHOLE)" -lt 700 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 3.0
APPLETVOS_DEPLOYMENT_TARGET := 0.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.6
DARWIN_DEPLOYMENT_VERSION   := 10
override MEMO_CFVER         := 600
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 500 ] && [ "$(CFVER_WHOLE)" -lt 600 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 2.0
APPLETVOS_DEPLOYMENT_TARGET := 0.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.6
DARWIN_DEPLOYMENT_VERSION   := 9
override MEMO_CFVER         := 500
else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 400 ] && [ "$(CFVER_WHOLE)" -lt 500 ] && echo 1),1)
IPHONEOS_DEPLOYMENT_TARGET  := 1.0
APPLETVOS_DEPLOYMENT_TARGET := 0.0
AUDIOOS_DEPLOYMENT_TARGET   := 0.0
BRIDGEOS_DEPLOYMENT_TARGET  := 0.0
WATCHOS_DEPLOYMENT_TARGET   := 0.0
MACOSX_DEPLOYMENT_TARGET    := 10.6
DARWIN_DEPLOYMENT_VERSION   := 9
override MEMO_CFVER         := 400
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
LLVM_TARGET           := armv7-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/iPhoneOS.sdk
BARE_PLATFORM         := iPhoneOS
MEMO_DEPLOYMENT       := IPHONEOS_DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)

else ifeq ($(shell [ "$(MEMO_TARGET)" = "iphoneos-armv6" ] || [ "$(MEMO_TARGET)" = "iphoneos-armv6-ramdisk" ] && echo 1),1)
ifneq ($(MEMO_QUIET),1)
$(warning Building for iOS)
endif # ($(MEMO_QUIET),1)
MEMO_ARCH             := armv6
PLATFORM              := iphoneos
DEB_ARCH              := iphoneos-arm
GNU_HOST_TRIPLE       := armv6-apple-darwin
PLATFORM_VERSION_MIN  := -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := armv6-apple-ios
LLVM_TARGET           := armv6-apple-ios$(IPHONEOS_DEPLOYMENT_TARGET)
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
LLVM_TARGET           := arm64e-apple-tvos$(APPLETVOS_DEPLOYMENT_TARGET)
MEMO_PREFIX           ?=
MEMO_SUB_PREFIX       ?= /usr
MEMO_ALT_PREFIX       ?= /local
MEMO_LAUNCHCTL_PREFIX ?= $(MEMO_PREFIX)
GNU_PREFIX            :=
ON_DEVICE_SDK_PATH    := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/AppleTVOS.sdk
BARE_PLATFORM         := AppleTVOS
MEMO_DEPLOYMENT       := APPLETVOS_DEPLOYMENT_TARGET=$(APPLETVOS_DEPLOYMENT_TARGET)

else ifeq ($(shell [ "$(MEMO_TARGET)" = "bridgeos-arm64" ] || [ "$(MEMO_TARGET)" = "bridgeos-arm64-ramdisk" ] && echo 1),1)
MEMO_ARCH             := arm64
PLATFORM              := iphoneos # find me a BridgeOS.sdk and you win.
DEB_ARCH              := bridgeos-arm64
GNU_HOST_TRIPLE       := aarch64-apple-darwin
PLATFORM_VERSION_MIN  := -mbridgeos-version-min=$(BRIDGEOS_DEPLOYMENT_TARGET)
RUST_TARGET           := aarch64-apple-bridgeos
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
RUST_TARGET           := aarch64-apple-watchos
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
LDFLAGS_FOR_BUILD  ?= 

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

else
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

endif
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
$(error Please use macOS, iOS, Linux, or FreeBSD to build)
endif

LD_FOR_BUILD  		:= $(shell command -v ld) $(LDFLAGS_FOR_BUILD)
CC_FOR_BUILD  		:= $(shell command -v cc) $(CFLAGS_FOR_BUILD)
CPP_FOR_BUILD 		:= $(shell command -v cc) -E $(CPPFLAGS_FOR_BUILD)
CXX_FOR_BUILD 		:= $(shell command -v c++) $(CXXFLAGS_FOR_BUILD)
AR_FOR_BUILD  		:= $(shell command -v ar)
NM_FOR_BUILD		:= $(shell command -v nm)
RANLIB_FOR_BUILD	:= $(shell command -v ranlib)
STRIP_FOR_BUILD		:= $(shell command -v strip)
export LD_FOR_BUILD CC_FOR_BUILD CPP_FOR_BUILD CXX_FOR_BUILD AR_FOR_BUILD NM_FOR_BUILD RANLIB_FOR_BUILD STRIP_FOR_BUILD

DEB_MAINTAINER    ?= Procursus Team <support@procurs.us>
MEMO_REPO_URI     ?= https://apt.procurs.us
MEMO_PGP_SIGN_KEY ?= C59F3798A305ADD7E7E6C7256430292CF9551B0E
CODESIGN_IDENTITY ?= -

MEMO_LDID_EXTRA_FLAGS     ?=
MEMO_CODESIGN_EXTRA_FLAGS ?=

LDID := ldid -Hsha1 -Hsha256 -Cadhoc $(MEMO_LDID_EXTRA_FLAGS)

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

CFLAGS              := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1 -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include/c++/v1 -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks
CXXFLAGS            := $(CFLAGS)
ASFLAGS             := $(CFLAGS)
CPPFLAGS            := -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1 -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include/c++/v1 -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include -Wno-error-implicit-function-declaration
LDFLAGS             := $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib -F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks -F$(BUILD_BASE)$(MEMO_PREFIX)/Library/Frameworks -Wl,-not_for_dyld_shared_cache
PKG_CONFIG_PATH     :=
ACLOCAL_PATH        := $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal

ifeq ($(MEMO_TARGET),bridgeos-arm64)
CFLAGS              += -Wno-incompatible-sysroot
CXXFLAGS            += -Wno-incompatible-sysroot
endif

ifeq ($(MEMO_ARCH),armv6)
# iOS 2 needs this.
CFLAGS              += -ffixed-r9
CXXFLAGS            += -ffixed-r9
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
	LD="$(LD_FOR_BUILD)" \
	AR="$(AR_FOR_BUILD)" \
	NM="$(NM_FOR_BUILD)" \
	RANLIB="$(RANLIB_FOR_BUILD)" \
	STRIP="$(STRIP_FOR_BUILD)" \
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
	destdir=$(BUILD_STAGE)/libmodule-build-perl \
	install_base=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	install_path=lib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
	install_path=arch=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$${PERL_MAJOR} \
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
						$(CURL) -s -w "%{http_code}" --output \
							$(1) $(2) | grep -q 404 && echo "FAILED TO DOWNLOAD $(1)"; \
					else \
						$(CURL) -s -w "%{http_code}" --output \
							$(1) $(2) | grep -q 404 && echo "FAILED TO DOWNLOAD $(1)" & \
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
		pkg="$$(echo $$pkg | sed 's/_CF/\#/g' | cut -d '\#' -f1)"; \
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
			$(STRIP) -x $$file; \
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
	mkdir -p $(BUILD_DIST)/../$$(echo $@ | awk '{split($$0,a,"_CF"); print a[1]}' | sed 's/-package//'); \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/../$$(echo $@ | awk '{split($$0,a,"_CF"); print a[1]}' | sed 's/-package//')/$$(grep Package: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ')_$($(2))_$$(grep Architecture: $(BUILD_DIST)/$(1)/DEBIAN/control | cut -f2 -d ' ').deb

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
CURL := curl --silent -L --create-dir
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
MAKEFLAGS += --jobs=$(CORE_COUNT) --load-average=$(CORE_COUNT)
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

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && echo 1),1)
RAMDISK_PROJECTS := bash coreutils diskdev-cmds file findutils gettext grep gzip libmd nano ncurses openssl openssh readline tar

else
RAMDISK_PROJECTS := bash coreutils openssl openssh readline ncurses libmd

endif


ramdisk:
	find $(BUILD_DIST)/../ -name "*.deb" -exec rm {} \; || true
	+MEMO_NO_IOSEXEC=1 $(MAKE) $(RAMDISK_PROJECTS:%=%-package)
	rm -rf $(BUILD_STRAP)/strap
	rm -rf $(BUILD_DIST)/strap
	rm -f $(BUILD_DIST)/bootstrap_tools.tar*
	rm -f $(BUILD_DIST)/.fakeroot_bootstrap
	touch $(BUILD_DIST)/.fakeroot_bootstrap

	rm -f $(BUILD_DIST)/../openssl/openssl_*.deb
	find $(BUILD_DIST)/../ -name "*-dev*.deb" -exec rm {} \;
	find $(BUILD_DIST)/../ -name "*-doc*.deb" -exec rm {} \;

	for DEB in $$(find $(BUILD_DIST)/../ -name "*.deb"); do \
		dpkg-deb -x $$DEB $(BUILD_DIST)/strap; \
	done
	ln -s $(MEMO_PREFIX)/bin/bash $(BUILD_DIST)/strap/$(MEMO_PREFIX)/bin/sh
	echo -e "/bin/sh\n" > $(BUILD_DIST)/strap/$(MEMO_PREFIX)/etc/shells
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/{*.a,pkgconfig,bash},share/{doc,man,readline}}
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{ssh,ssh-add,ssh-agent,ssh-copy-id,ssh-keyscan}
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 800 ] && echo 1),1)
	# Ramdisk size limit is 32MB o.O
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{b2sum,base32,base64,dircolors,captoinfo,chcon,chgrp,cksum,comm,csplit,expr,factor,fmt,fold,hostid,infocmp,infotocap,install,join,logname,mkfifo,mktemp,nl,nproc,numfmt,od,openssl,pathchk,pinky,pr,ptx,reset,runcon,sha224sum,sha256sum,sha384sum,sha512sum,shred,shuf,tac,timeout,tic,toe,tput,unexpand,vdir,wc,yes}
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/../bin/{chgrp,vdir}
	rm -rf $(BUILD_DIST)/strap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ssh-pkcs11-helper
endif
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
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1800 ] && echo 1),1)
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
	gpg --armor -u $(MEMO_PGP_SIGN_KEY) --detach-sign $(BUILD_STRAP)/$${BOOTSTRAP}; \
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
