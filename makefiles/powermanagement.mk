ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS             += powermanagement
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
POWERMANAGEMENT_VERSION := 1132.50.3
PMTOOL_EXT              := c
else
POWERMANAGEMENT_VERSION := 1303.80.3
PMTOOL_EXT              := m
endif
DEB_POWERMANAGEMENT_V   ?= $(POWERMANAGEMENT_VERSION)

powermanagement-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,PowerManagement,$(POWERMANAGEMENT_VERSION),PowerManagement-$(POWERMANAGEMENT_VERSION))
	$(call EXTRACT_TAR,PowerManagement-$(POWERMANAGEMENT_VERSION).tar.gz,PowerManagement-PowerManagement-$(POWERMANAGEMENT_VERSION),powermanagement)
	sed -i 's|#include <CoreFoundation/CFPreferences_Private.h>|#include <CoreFoundation/CFPreferences.h>|' $(BUILD_WORK)/powermanagement/{pmtool/pmtool.h,pmconfigd/BatteryTimeRemaining.m}
	sed -i -e 's|IOReportIterationResult||' -e '1s|^|unsigned long iter;\n|' -e 's/#define PLATFORM_HAS_DISPLAYSERVICES    1/#define PLATFORM_HAS_DISPLAYSERVICES    0/' $(BUILD_WORK)/powermanagement/pmset/pmset.c
	sed -i -e '/inactivityWindowType/d' -e 's|#include "CommonLib.h"|#include "$(BUILD_WORK)/powermanagement/common/CommonLib.h"|g' $(BUILD_WORK)/powermanagement/pmconfigd/PrivateLib.h
	sed -i 's|#include <MobileKeyBag/MobileKeyBag.h>||' $(BUILD_WORK)/powermanagement/pmconfigd/BatteryTimeRemaining.m

ifneq ($(wildcard $(BUILD_WORK)/powermanagement/.build_complete),)
powermanagement:
	@echo "Using previously built powermanagement."
else
powermanagement: powermanagement-setup
	mkdir -p $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,8}}
	cd $(BUILD_WORK)/powermanagement/pmconfigd; \
		mig -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) -isysroot $(BUILD_BASE) powermanagement.defs;
	cd $(BUILD_WORK)/powermanagement; \
		$(CC) $(CFLAGS) -DPRIVATE -D__OS_EXPOSE_INTERNALS__ -Ipmconfigd -IAppleSmartBatteryManager -c common/CommonLib.c;
	cd $(BUILD_WORK)/powermanagement; \
		$(CC) $(LDFLAGS) -framework CoreFoundation -framework IOKit -Icommon -Ipmconfigd $(CFLAGS) -o $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pmtool pmtool/*.$(PMTOOL_EXT); \
		$(CC) $(LDFLAGS) -framework CoreFoundation -framework IOKit -Icommon -Ipmconfigd $(CFLAGS) -o $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/caffeinate caffeinate/*.c; \
		$(CC) $(LDFLAGS) -Wno-error-implicit-function-declaration CommonLib.o -framework CoreFoundation -framework SystemConfiguration -framework IOKit -Icommon -Ipmconfigd $(CFLAGS) $(BUILD_MISC)/powermanagement/libIOReport.tbd -o $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pmset pmset/pmset.c; \
		$(INSTALL) -m644 pmtool/pmtool.1 $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
		$(INSTALL) -m644 pmset/pmset.1 $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
		$(INSTALL) -m644 caffeinate/caffeinate.8 $(BUILD_STAGE)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8;
	$(call AFTER_BUILD)
endif

powermanagement-package: powermanagement-stage
	# powermanagement.mk Package Structure
	rm -rf $(BUILD_DIST)/powermanagement

	# powermanagement.mk Prep powermanagement
	cp -a $(BUILD_STAGE)/powermanagement $(BUILD_DIST)

	# powermanagement.mk Sign
	$(LDID) -S$(BUILD_MISC)/entitlements/pmtool.xml $(BUILD_DIST)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pmtool
	$(LDID) -S$(BUILD_MISC)/entitlements/pmset.xml $(BUILD_DIST)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pmset
	$(LDID) -S$(BUILD_MISC)/entitlements/general.xml $(BUILD_DIST)/powermanagement/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/caffeinate

	# powermanagement.mk Make .debs
	$(call PACK,powermanagement,DEB_POWERMANAGEMENT_V)

	# powermanagement.mk Build cleanup
	rm -rf $(BUILD_DIST)/powermanagement

.PHONY: powermanagement powermanagement-package

endif
