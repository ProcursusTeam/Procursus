ifeq ($(firstword $(subst ., ,$(MAKE_VERSION))),3)
$(error Install latest make from Homebrew - brew install make)
endif

SHELL           := /usr/bin/env bash
UNAME           := $(shell uname -s)
SUBPROJECTS     += $(STRAPPROJECTS)

ifneq ($(shell umask),0022)
$(error Please run `umask 022` before running this)
endif

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
EXTRA    := INSTALL="/usr/bin/install -c --strip-program=$(STRIP)"
export CC CXX AR RANLIB STRIP

else ifeq ($(UNAME),Darwin)
$(warning Building on MacOS)
SYSROOT         ?= $(THEOS)/sdks/iPhoneOS12.2.sdk
MACOSX_SYSROOT  ?= $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
I_N_T           := install_name_tool
EXTRA           :=
else
$(error Please use Linux or MacOS to build)
endif

iphoneos_VERSION_MIN := -miphoneos-version-min=11.0

DEB_ARCH       := iphoneos-arm
DEB_ORIGIN     := checkra1n
DEB_MAINTAINER := Hayden Seay <me@diatr.us>

# Root
BUILD_ROOT     ?= $(PWD)
# Downloaded source files
BUILD_SOURCE   ?= $(BUILD_ROOT)/build_source
# Base headers/libs (e.g. patched from SDK)
BUILD_BASE     ?= $(BUILD_ROOT)/build_base
# Dpkg info storage area
BUILD_INFO     ?= $(BUILD_ROOT)/build_info
# Extracted source working directory
BUILD_WORK     ?= $(BUILD_ROOT)/build_work
# Bootstrap working area
BUILD_STAGE    ?= $(BUILD_ROOT)/build_stage
# Final output
BUILD_DIST     ?= $(BUILD_ROOT)/build_dist
# Actual bootrap staging
BUILD_STRAP    ?= $(BUILD_ROOT)/build_strap
# Extra scripts for the buildsystem
BUILD_TOOLS    ?= $(BUILD_ROOT)/build_tools

CFLAGS          := -O2 -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include
CXXFLAGS        := $(CFLAGS)
CPPFLAGS        := $(CFLAGS)
LDFLAGS         := -L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib
PKG_CONFIG_PATH := $(BUILD_BASE)/usr/lib/pkgconfig

export PLATFORM ARCH SYSROOT MACOSX_SYSROOT GNU_HOST_TRIPLE I_N_T EXTRA
export BUILD_BASE BUILD_INFO BUILD_WORK BUILD_STAGE BUILD_DIST BUILD_STRAP BUILD_TOOLS
export DEB_ARCH DEB_ORIGIN DEB_MAINTAINER
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG_PATH

HAS_COMMAND = $(shell type $(1) >/dev/null 2>&1 && echo 1)
PGP_VERIFY  = gpg --verify $(BUILD_SOURCE)/$(1).$(if $(2),$(2),sig) $(BUILD_SOURCE)/$(1) 2>&1 | grep -q 'Good signature'

EXTRACT_TAR = if [ ! -d $(BUILD_WORK)/$(3) ] || [ "$(4)" = "1" ]; then \
		cd $(BUILD_WORK) && \
		$(TAR) -xf $(BUILD_SOURCE)/$(1) && \
		mkdir -p $(3); 2>/dev/null || :; \
		cp -af $(2)/* $(3) 2>/dev/null || :; \
		rm -rf $(2); 2>/dev/null || :; \
	fi

DO_PATCH    = cd $(BUILD_WORK)/$(1)-patches; \
	rm -f ./series; \
	for PATCHFILE in *; do \
		if [ ! -f $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done ]; then \
			$(PATCH) -sN -d $(BUILD_WORK)/$(2) $(3) < $$PATCHFILE &> /dev/null; \
			if [ $(4) ]; then \
				$(PATCH) -sN -d $(BUILD_WORK)/$(2) $(4) < $$PATCHFILE &> /dev/null; \
			fi; \
			touch $(BUILD_WORK)/$(2)/$(notdir $$PATCHFILE).done; \
		fi; \
	done

SIGN =  find $(BUILD_DIST)/$(1) -type f -exec $(LDID) -S$(BUILD_INFO)/$(2) {} \; &> /dev/null; \
	find $(BUILD_DIST)/$(1) -name '.ldid*' -type f -delete
		
PACK =  find $(BUILD_DIST)/$(1) \( -name '*.la' -o -name '*.a' \) -type f -delete; \
	rm -rf $(BUILD_DIST)/$(1)/usr/share/{info,aclocal,doc}; \
	if [ -z $(3) ]; then \
		echo Setting $(1) owner to 0:0.; \
		$(FAKEROOT) chown -R 0:0 $(BUILD_DIST)/$(1)/*; \
	elif [ $(3) = "2" ]; then \
		echo $(1) owner set within individual makefile.; \
	fi; \
	SIZE=$$(du -s $(BUILD_DIST)/$(1) | cut -f 1); \
	mkdir -p $(BUILD_DIST)/$(1)/DEBIAN; \
	cp $(BUILD_INFO)/$(1).control $(BUILD_DIST)/$(1)/DEBIAN/control; \
	cp $(BUILD_INFO)/$(1).postinst $(BUILD_DIST)/$(1)/DEBIAN/postinst 2>/dev/null || :; \
	cp $(BUILD_INFO)/$(1).preinst $(BUILD_DIST)/$(1)/DEBIAN/preinst 2>/dev/null || :; \
	cp $(BUILD_INFO)/$(1).postrm $(BUILD_DIST)/$(1)/DEBIAN/postrm 2>/dev/null || :; \
	cp $(BUILD_INFO)/$(1).prerm $(BUILD_DIST)/$(1)/DEBIAN/prerm 2>/dev/null || :; \
	cp $(BUILD_INFO)/$(1).extrainst_ $(BUILD_DIST)/$(1)/DEBIAN/extrainst_ 2>/dev/null || :; \
	cd $(BUILD_DIST)/$(1) && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > $(BUILD_DIST)/$(1)/DEBIAN/md5sums; \
	chmod 0755 $(BUILD_DIST)/$(1)/DEBIAN/*; \
	$(SED) -i ':a; s/@$(2)@/$($(2))/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/$(1)/DEBIAN/control; \
	echo "Installed-Size: $$SIZE"; \
	echo "Installed-Size: $$SIZE" >> $(BUILD_DIST)/$(1)/DEBIAN/control; \
	$(FAKEROOT) $(DPKG_DEB) -b $(BUILD_DIST)/$(1) $(BUILD_DIST)/$(1)_$($(2))_$(DEB_ARCH).deb

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

ifneq ($(call HAS_COMMAND,yacc),1)
$(error Install bison)
endif

ifneq ($(call HAS_COMMAND,lex),1)
$(error Install flex)
endif

ifneq ($(call HAS_COMMAND,groff),1)
$(error Install groff)
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
#FAKEROOT := fakeroot -i $(PWD)/.fakeroot_persist -s $(PWD)/.fakeroot_persist --
#FAKEROOT := fakeroot
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
MAKEFLAGS += --jobs=$(shell $(GET_LOGICAL_CORES)) -Otarget
endif

CHECKRA1N_MEMO := 1

all:: package
	@echo "********** Successfully built debs for **********"
	@echo "$(SUBPROJECTS)"
	$(BUILD_TOOLS)/check_gettext.sh

include *.mk

package:: $(SUBPROJECTS:%=%-package)
bootstrap:: export BUILD_DIST=$(BUILD_STRAP)
bootstrap:: $(STRAPPROJECTS:%=%-package)
	rm -rf $(BUILD_STRAP)/strap
	rm -f $(BUILD_STAGE)/.fakeroot_bootstrap
	touch $(BUILD_STAGE)/.fakeroot_bootstrap
	mkdir -p $(BUILD_STRAP)/strap/Library/dpkg/info
	touch $(BUILD_STRAP)/strap/Library/dpkg/status
	cd $(BUILD_STRAP) && rm -f apt-*.deb dpkg-*.deb
	for DEB in $(BUILD_STRAP)/*.deb; do \
		PKGNAME=$$(basename $$DEB | cut -f1 -d"_"); \
		dpkg-deb -R $$DEB $(BUILD_STRAP)/strap; \
		cp $(BUILD_STRAP)/strap/DEBIAN/md5sums $(BUILD_STRAP)/strap/Library/dpkg/info/$$PKGNAME.md5sums; \
		dpkg-deb -c $$DEB | cut -f2- -d"." | awk -F'\\-\\>' '{print $$1}' | $(SED) '1 s/$$/./' | $(SED) 's/\/$$//' > $(BUILD_STRAP)/strap/Library/dpkg/info/$$PKGNAME.list; \
		cp $(BUILD_INFO)/$$PKGNAME.{preinst,postinst,extrainst_,prerm,postrm} $(BUILD_STRAP)/strap/Library/dpkg/info 2>/dev/null || :; \
		dpkg-deb --info $$DEB | $(SED) '/Package:/,$$!d' | $(SED) -e 's/^[ \t]*//' >> $(BUILD_STRAP)/strap/Library/dpkg/status; \
		echo -e "Status: install ok installed\n" >> $(BUILD_STRAP)/strap/Library/dpkg/status; \
		rm -rf $(BUILD_STRAP)/strap/DEBIAN; \
	done
	$(RMDIR) --ignore-fail-on-non-empty $(BUILD_STRAP)/strap/{Applications,bin,dev,etc/{default,profile.d},Library/{Frameworks,LaunchAgents,LaunchDaemons,Preferences,Ringtones,Wallpaper},sbin,System/Library/{Extensions,Fonts,Frameworks,Internet\ Plug-Ins,KeyboardDictionaries,LaunchDaemons,PreferenceBundles,PrivateFrameworks,SystemConfiguration,VideoDecoders},System/Library,System,tmp,usr/{bin,games,include,sbin,var,share/{dict,misc}},var/{backups,cache,db,lib/misc,local,lock,logs,mobile/{Library/Preferences,Library,Media},mobile,msgs,preferences,root/Media,root,run,spool,tmp,vm}}
	mkdir -p $(BUILD_STRAP)/strap/private
	rm -f $(BUILD_STRAP)/strap/{sbin/{fsck,fsck_apfs,fsck_exfat,fsck_hfs,fsck_msdos,launchd,mount,mount_apfs,newfs_apfs,newfs_hfs,pfctl},usr/sbin/{BTAvrcp,BTLEServer,BTMap,BTPbap,BlueTool,WirelessRadioManagerd,absd,addNetworkInterface,aslmanager,bluetoothd,cfprefsd,distnoted,filecoordinationd,ioreg,ipconfig,mDNSResponder,mDNSResponderHelper,mediaserverd,notifyd,nvram,pppd,racoon,rtadvd,scutil,spindump,syslogd,wifid}}
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
	export FAKEROOT='fakeroot -i $(BUILD_STAGE)/.fakeroot_bootstrap -s $(BUILD_STAGE)/.fakeroot_bootstrap --'; \
	$$FAKEROOT chown 0:80 $(BUILD_STRAP)/strap/Library; \
	$$FAKEROOT chown 0:3 $(BUILD_STRAP)/strap/private/var/empty; \
	$$FAKEROOT chown 0:1 $(BUILD_STRAP)/strap/private/var/run; \
	cd $(BUILD_STRAP)/strap && $$FAKEROOT $(TAR) -czvf ../bootstrap.tar.gz . &>/dev/null
	rm -rf $(BUILD_STRAP)/{strap,*.deb}
	@echo "********** Successfully built bootstrap with **********"
	@echo "$(STRAPPROJECTS)"
	@echo "$(BUILD_STRAP)/bootstrap.tar.gz"

bootstrap-device: bootstrap
	@echo "********** Bootstrapping device. This may take a while! **********"
	$(BUILD_TOOLS)/bootstrap_device.sh

%-package: FAKEROOT=fakeroot -i $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) -s $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev) --
%-stage: %
	rm -f $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)
	touch $(BUILD_STAGE)/.fakeroot_$$(echo $@ | rev | cut -f2- -d"-" | rev)
	find $(BUILD_BASE)/usr/lib -name "*.la" -type f -delete

REPROJ=$(shell echo $@ | cut -f2- -d"-")
REPROJ2=$(shell echo $(REPROJ) | sed 's/-package//')
rebuild-%:
	@echo Rebuild $(REPROJ2)
	if [ $(REPROJ) = "all" ] | [ $(REPROJ) = "package" ]; then \
		rm -rf $(BUILD_WORK) $(BUILD_STAGE); \
		git submodule foreach --recursive git clean -xfd; \
		git submodule foreach --recursive git reset --hard; \
		rm -f darwintools/.build_complete; \
		$(MAKE) -C darwintools clean 2>/dev/null || :; \
	fi
	if [ -d $(BUILD_WORK)/$(REPROJ2) ]; then \
		rm -rf {$(BUILD_WORK),$(BUILD_STAGE)}/$(REPROJ2); \
	elif [ -d $(REPROJ2) ]; then \
		cd $(REPROJ2) && git clean -xfd && git reset 2>/dev/null || :; \
	fi
	+$(MAKE) $(REPROJ)

.PHONY: $(SUBPROJECTS)

setup:
	mkdir -p \
		$(BUILD_BASE) $(BUILD_BASE)/usr/{include,lib} \
		$(BUILD_WORK) $(BUILD_STAGE) $(BUILD_DIST) $(BUILD_STRAP)

	git submodule update --init --recursive

	wget -q -nc -P $(BUILD_SOURCE) $(DOWNLOAD)

	mkdir -p $(BUILD_BASE)/usr/include/{sys,IOKit}

	@# Copy headers from MacOSX.sdk
	cp -a $(MACOSX_SYSROOT)/usr/include/{arpa,net,xpc} $(BUILD_BASE)/usr/include
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/{tty*,proc*,kern*}.h $(BUILD_BASE)/usr/include/sys
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/ps $(BUILD_BASE)/usr/include/IOKit
	cp -a $(MACOSX_SYSROOT)/usr/include/{ar,launch,libproc,tzfile}.h $(BUILD_BASE)/usr/include

	@# Patch headers from iPhoneOS.sdk
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(SYSROOT)/usr/include/stdlib.h > $(BUILD_BASE)/usr/include/stdlib.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(SYSROOT)/usr/include/time.h > $(BUILD_BASE)/usr/include/time.h

	@echo Makeflags: $(MAKEFLAGS)

clean::
	rm -rf $(BUILD_BASE) $(BUILD_WORK) $(BUILD_STAGE)
	@# When using 'make clean' in submodules, there is still an issue with the subproject changing when committing. This fixes that.
	git submodule foreach --recursive git clean -xfd
	git submodule foreach --recursive git reset --hard
	rm -f darwintools/.build_complete
	$(MAKE) -C darwintools clean 2>/dev/null || :

extreme-clean:: clean
	git clean -xfd && git reset

.PHONY: clean setup
