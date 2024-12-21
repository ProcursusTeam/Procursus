ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS     += configd
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
CONFIGD_VERSION := 1109.40.9
SCUTIL_EXTRA_C  := $(BUILD_WORK)/configd/Plugins/common/{InterfaceNamerControlPrefs,IPMonitorControlPrefs}.c
else ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1900 ] && echo 1),1)
CONFIGD_VERSION := 1163.40.8
SCUTIL_EXTRA_C  := $(BUILD_WORK)/configd/Plugins/common/{InterfaceNamerControlPrefs,IPMonitorControlPrefs}.c
else ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 2000 ] && echo 1),1)
CONFIGD_VERSION := 1241.40.2
SCUTIL_EXTRA_C  := $(BUILD_WORK)/configd/Plugins/{InterfaceNamer/Control/InterfaceNamer,IPMonitor/Control/IPMonitor}ControlPrefs.c
else ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 3000 ] && echo 1),1)
CONFIGD_VERSION := 1296.0.1
SCUTIL_EXTRA_C  := $(BUILD_WORK)/configd/Plugins/{InterfaceNamer/Control/InterfaceNamer,IPMonitor/Control/IPMonitor}ControlPrefs.c
else
CONFIGD_VERSION := 1345
SCUTIL_EXTRA_C  := $(BUILD_WORK)/configd/Plugins/{InterfaceNamer/Control/InterfaceNamer,IPMonitor/Control/IPMonitor}ControlPrefs.c
endif
DEB_CONFIGD_V   ?= $(CONFIGD_VERSION)

CONFIGD_CFLAGS  := -I$(BUILD_WORK)/configd/{,SystemConfiguration,IPMonitorControl,Plugins/{{IPMonitor,InterfaceNamer}/Control,common},dnsinfo,nwi} -D__OS_EXPOSE_INTERNALS__ -DPRIVATE -include $(BUILD_MISC)/configd/log_pack.h
CONFIGD_LIBS    := -framework CoreFoundation -framework SystemConfiguration

configd-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,configd,$(CONFIGD_VERSION),configd-$(CONFIGD_VERSION))
	$(call EXTRACT_TAR,configd-$(CONFIGD_VERSION).tar.gz,configd-configd-$(CONFIGD_VERSION),configd)
	ln -s $(BUILD_WORK)/configd/SystemConfiguration{.fproj,}
	cp -a $(BUILD_MISC)/configd/VPNConfiguration.h $(BUILD_WORK)/configd/SystemConfiguration
	sed -i 's|#include <os/state_private.h>||' $(BUILD_WORK)/configd/SystemConfiguration/SCPreferencesInternal.h
	mkdir -p $(BUILD_STAGE)/configd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/man8}

ifneq ($(wildcard $(BUILD_WORK)/configd/.build_complete),)
configd:
	@echo "Using previously built configd."
else
configd: configd-setup libedit
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && echo 1),1)
	$(CC) $(CONFIGD_CFLAGS) $(CONFIGD_LIBS) $(CFLAGS) $(LDFLAGS) -ledit $(BUILD_WORK)/configd/scutil.tproj/*.c $(SCUTIL_EXTRA_C) -o $(BUILD_STAGE)/configd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/scutil
endif
	$(CC) $(CONFIGD_CFLAGS) $(CONFIGD_LIBS) $(CFLAGS) $(LDFLAGS)  $(BUILD_WORK)/configd/scselect.tproj/*.c -o $(BUILD_STAGE)/configd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/scselect
	install -m644 $(BUILD_WORK)/configd/{scutil.tproj/scutil,scselect.tproj/scselect}.8 $(BUILD_STAGE)/configd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

configd-package: configd-stage
	# configd.mk Package Structure
	rm -rf $(BUILD_DIST)/scutil

	# configd.mk Prep scutil
	cp -a $(BUILD_STAGE)/configd $(BUILD_DIST)/scutil

	# configd.mk Sign
	$(call SIGN,scutil,scutil.xml)

	# configd.mk Make .debs
	$(call PACK,scutil,DEB_CONFIGD_V)

	# configd.mk Build cleanup
	rm -rf $(BUILD_DIST)/scutil

.PHONY: configd configd-package
endif
