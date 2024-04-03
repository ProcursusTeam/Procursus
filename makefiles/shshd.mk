ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

### TODO: Update upstream

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

ifeq ($(call HAS_COMMAND,swiftc),1)
STRAPPROJECTS += shshd
else
SUBPROJECTS   += shshd
endif
SHSHD_VERSION := 1.1.1.1
DEB_SHSHD_V   ?= $(SHSHD_VERSION)

ifneq ($(shell command -v xcrun),)
SWIFTC != xcrun --find swiftc
else
SWIFTC = swiftc
endif

shshd-setup: setup
	$(call GITHUB_ARCHIVE,Diatrus,SHSHDaemon,$(SHSHD_VERSION),v$(SHSHD_VERSION))
	$(call EXTRACT_TAR,SHSHDaemon-$(SHSHD_VERSION).tar.gz,SHSHDaemon-$(SHSHD_VERSION),shshd)
	mkdir -p $(BUILD_STAGE)/shshd/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{sbin,libexec}}
	mkdir -p $(BUILD_WORK)/shshd/include
	$(LN_S) $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/IOKit $(BUILD_WORK)/shshd/include/IOKit
	sed -i 's|kIOMainPortDefault|gang_kIOMasterPortDefault|' $(BUILD_WORK)/shshd/main.swift
	if ! [ grep -q "gang_kIOMasterPortDefault" $(BUILD_WORK)/shshd/Bridge.h ]; then printf 'const mach_port_t gang_kIOMasterPortDefault asm ("_kIOMasterPortDefault");\n' >> $(BUILD_WORK)/shshd/Bridge.h; fi

ifneq ($(wildcard $(BUILD_WORK)/shshd/.build_complete),)
shshd:
	@echo "Using previously built shshd."
else
shshd: shshd-setup dimentio
	cd $(BUILD_WORK)/shshd; \
		$(SWIFTC) -Osize \
			--target=$(LLVM_TARGET) \
			-sdk $(TARGET_SYSROOT) \
			-I$(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
			-I$(BUILD_WORK)/shshd/include \
			-F$(BUILD_BASE)$(MEMO_PREFIX)/System/Library/Frameworks \
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
