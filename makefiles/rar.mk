ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq ($(MEMO_ARCH),armv7k)
ifneq ($(MEMO_ARCH),arm64_32)
ifneq ($(MEMO_ARCH),arm64e)

SUBPROJECTS   += rar
RAR_VERSION   := 6.1
RAR_BUILD     := 610
DEB_RAR_V     ?= $(RAR_VERSION)
DEBIAN_RAR_V  := 5.5.0-1.1

# XXX: needs severe cleaning

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version ios $(IPHONEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar rar
endif # ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
ifneq (,$(findstring appletvos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version tvos $(APPLETVOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar rar
endif # ifneq (,$(findstring appletvos,$(MEMO_TARGET)))
ifneq (,$(findstring audioos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version tvos $(AUDIOOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar rar
endif # ifneq (,$(findstring audioos,$(MEMO_TARGET)))
ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version bridgeos $(BRIDGEOS_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar rar
endif # ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
RAR_INSTALL := vtool -set-build-version macos $(MACOSX_DEPLOYMENT_TARGET) $(BARE_PLATFORM) -output $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rar rar
endif # ifneq (,$(findstring darwin,$(MEMO_TARGET)))

rar-setup: setup
ifeq ($(MEMO_ARCH),x86_64)
	wget2 -q -nc -P$(BUILD_SOURCE) https://www.rarlab.com/rar/rarmacos-x64-$(RAR_BUILD).tar.gz
	tar -C $(BUILD_WORK) -xf $(BUILD_SOURCE)/rarmacos-x64-$(RAR_BUILD).tar.gz
endif
ifeq ($(MEMO_ARCH),arm64)
	wget2 -q -nc -P$(BUILD_SOURCE) https://www.rarlab.com/rar/rarmacos-arm-$(RAR_BUILD).tar.gz
	tar -C $(BUILD_WORK) -xf $(BUILD_SOURCE)/rarmacos-arm-$(RAR_BUILD).tar.gz
endif
	wget2 -q -nc -P$(BUILD_SOURCE) http://deb.debian.org/debian/pool/non-free/r/rar/rar_$(DEBIAN_RAR_V).debian.tar.xz
	tar -C $(BUILD_WORK)/rar -xJf $(BUILD_SOURCE)/rar_$(DEBIAN_RAR_V).debian.tar.xz
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
	cd $(BUILD_WORK)/rar && $(RAR_INSTALL); \
	install -m644 rarfiles.lst $(BUILD_STAGE)/rar/$(MEMO_PREFIX)/etc; \
	install -m644 debian/rar.1 $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	install -m644 default.sfx $(BUILD_STAGE)/rar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(call AFTER_BUILD)
endif # ifneq ($(wildcard $(BUILD_WORK)/rar/.build_complete),)

rar-package: rar-stage
	# rar.mk Package Structure
	rm -rf $(BUILD_DIST)/rar

	# rar.mk Prep rar
	cp -a $(BUILD_STAGE)/rar $(BUILD_DIST)

	# rar.mk Sign
	$(call SIGN,rar,general.xml)

	# rar.mk Make .debs
	$(call PACK,rar,DEB_RAR_V)

	# rar.mk Build cleanup
	rm -rf $(BUILD_DIST)/rar

.PHONY: rar rar-package

endif # ifeq ($(MEMO_ARCH),arm64e)
endif # ifeq ($(MEMO_ARCH),arm64_32)
endif # ifeq ($(MEMO_ARCH),armv7k)
