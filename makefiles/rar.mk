ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq ($(MEMO_ARCH),armv7k)
ifneq ($(MEMO_ARCH),arm64_32)
ifneq ($(MEMO_ARCH),arm64e)

SUBPROJECTS   += rar
RAR_VERSION   := 7.0.1
RAR_BUILD     := 701
DEB_RAR_V     ?= $(RAR_VERSION)
DEBIAN_RAR_V  := 7.00-1

RAR_HELPER_SRC = $(BUILD_WORK)/rar/open_hook.c $(BUILD_MISC)/rar/litehook.c

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
ifeq ($(MEMO_ARCH),arm64)
RAR_HELPER_SRC += $(BUILD_MISC)/rar/rar_helper.S
endif # ifeq ($(MEMO_ARCH),arm64)
endif # ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)

# XXX: needs severe cleaning

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version ios $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar_bin rar; \
	vtool -set-build-version ios $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx default.sfx
endif # ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
ifneq (,$(findstring appletvos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version tvos $(APPLETVOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar_bin rar; \
	vtool -set-build-version tvos $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx default.sfx
endif # ifneq (,$(findstring appletvos,$(MEMO_TARGET)))
ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version bridgeos $(BRIDGEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar_bin rar; \
	vtool -set-build-version bridgeos $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx default.sfx
endif # ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version macos $(MACOSX_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar_bin rar; \
	vtool -set-build-version macos $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx default.sfx
endif # ifneq (,$(findstring darwin,$(MEMO_TARGET)))

rar-setup: setup
ifeq ($(MEMO_ARCH),x86_64)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.rarlab.com/rar/rarmacos-x64-$(RAR_BUILD).tar.gz)
	tar -C $(BUILD_WORK) -xf $(BUILD_SOURCE)/rarmacos-x64-$(RAR_BUILD).tar.gz
endif # ifeq ($(MEMO_ARCH),x86_64)
ifeq ($(MEMO_ARCH),arm64)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.rarlab.com/rar/rarmacos-arm-$(RAR_BUILD).tar.gz)
	tar -C $(BUILD_WORK) -xf $(BUILD_SOURCE)/rarmacos-arm-$(RAR_BUILD).tar.gz
endif # ifeq ($(MEMO_ARCH),arm64)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://deb.debian.org/debian/pool/non-free/r/rar/rar_$(DEBIAN_RAR_V).debian.tar.xz)
	tar -C $(BUILD_WORK)/rar -xJf $(BUILD_SOURCE)/rar_$(DEBIAN_RAR_V).debian.tar.xz
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/rar/open_hook.c > $(BUILD_WORK)/rar/open_hook.c
	mkdir -p $(BUILD_STAGE)/rar/$(MEMO_PREFIX){$(MEMO_SUB_PREFIX)/{bin,lib,share/man/man1},/etc}

ifneq ($(wildcard $(BUILD_WORK)/rar/.build_complete),)
rar:
	@echo "Using previously built rar."
else
rar: rar-setup
	mv $(BUILD_WORK)/rar/{license.txt,LICENSE}
	mv $(BUILD_WORK)/rar/{acknow.txt,THANKS}
	cat $(BUILD_WORK)/rar/{readme,rar}.txt >> $(BUILD_WORK)/rar/README
	vtool -remove-build-version macos -replace -output $(BUILD_WORK)/rar/rar $(BUILD_WORK)/rar/rar # needed to prevent "malformed object"
	vtool -remove-build-version macos -replace -output $(BUILD_WORK)/rar/default.sfx $(BUILD_WORK)/rar/default.sfx
	cd $(BUILD_WORK)/rar && $(RAR_INSTALL); \
	install -m644 rarfiles.lst $(BUILD_STAGE)/rar/$(MEMO_PREFIX)/etc; \
	install -m644 debian/rar.1 $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1;
	chmod 644 $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -I$(BUILD_MISC)/rar $(RAR_HELPER_SRC) -o $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librarhelper.dylib
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/rar/shim.sh > $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar
	chmod 755 $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar
	$(call AFTER_BUILD)
endif # ifneq ($(wildcard $(BUILD_WORK)/rar/.build_complete),)

rar-package: rar-stage
	# rar.mk Package Structure
	rm -rf $(BUILD_DIST)/rar

	# rar.mk Prep rar
	cp -a $(BUILD_STAGE)/rar $(BUILD_DIST)

	# rar.mk Sign
	$(call SIGN,rar,rar.xml)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	codesign $(MEMO_CODESIGN_EXTRA_FLAGS) --sign $(CODESIGN_IDENTITY) --force --deep --entitlements $(BUILD_MISC)/entitlements/rar-macos.xml $(BUILD_DIST)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar_bin

	# We do not want the codesign identity being used on random SFX files
	$(LDID) -S $(BUILD_DIST)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/default.sfx
endif

	# rar.mk Make .debs
	$(call PACK,rar,DEB_RAR_V)

	# rar.mk Build cleanup
	rm -rf $(BUILD_DIST)/rar

.PHONY: rar rar-package

endif # ifeq ($(MEMO_ARCH),arm64e)
endif # ifeq ($(MEMO_ARCH),arm64_32)
endif # ifeq ($(MEMO_ARCH),armv7k)
