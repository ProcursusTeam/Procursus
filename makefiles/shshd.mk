ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

### HOLD: No longer compatible with pre-iOS 15. This is acceptable, as shshd pre-iOS 15 is complete.

### TODO: Update upstream

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

ifeq ($(call HAS_COMMAND,swiftc),1)
STRAPPROJECTS += shshd
else
SUBPROJECTS   += shshd
endif
SHSHD_VERSION := 1.1.1.1
DEB_SHSHD_V   ?= $(SHSHD_VERSION)

shshd-setup: setup
	$(call GITHUB_ARCHIVE,Diatrus,SHSHDaemon,$(SHSHD_VERSION),v$(SHSHD_VERSION))
	$(call EXTRACT_TAR,SHSHDaemon-$(SHSHD_VERSION).tar.gz,SHSHDaemon-$(SHSHD_VERSION),shshd)
	mkdir -p $(BUILD_STAGE)/shshd/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{sbin,libexec}}
	sed -i 's|kIOMasterPortDefault|kIOMainPortDefault|' $(BUILD_WORK)/shshd/main.swift

ifneq ($(wildcard $(BUILD_WORK)/shshd/.build_complete),)
shshd:
	@echo "Using previously built shshd."
else
shshd: shshd-setup dimentio
	cd $(BUILD_WORK)/shshd; \
		swiftc -Osize \
			--target=$(LLVM_TARGET) \
			-sdk $(TARGET_SYSROOT) \
			-I$(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
			-import-objc-header Bridge.h \
			-o $(BUILD_STAGE)/shshd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/shshd \
			main.swift \
			-framework IOKit -lMobileGestalt \
			-L$(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -ldimentio \
			-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec
		sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/shshd/shshd-wrapper > $(BUILD_STAGE)/shshd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/shshd-wrapper
		chmod 0755 $(BUILD_STAGE)/shshd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/shshd-wrapper
		sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/shshd/us.diatr.shshd.plist > $(BUILD_STAGE)/shshd/$(MEMO_PREFIX)/Library/LaunchDaemons/us.diatr.shshd.plist
	$(call AFTER_BUILD)
endif

shshd-package: shshd-stage
	# shshd.mk Package Structure
	rm -rf $(BUILD_DIST)/shshd

	# shshd.mk Prep libshshd$(SHSHD_SOVERSION)
	cp -a $(BUILD_STAGE)/shshd $(BUILD_DIST)

	# shshd.mk Sign
	$(call SIGN,shshd,dimentio.plist)

	# shshd.mk Permissions
	chmod u+s $(BUILD_DIST)/shshd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/shshd

	# shshd.mk Make .debs
	$(call PACK,shshd,DEB_SHSHD_V)

	# shshd.mk Build cleanup
	rm -rf $(BUILD_DIST)/shshd

.PHONY: shshd shshd-package

endif
