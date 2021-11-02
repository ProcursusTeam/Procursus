ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPPROJECTS += hdik
HDIK_VERSION := 1
DEB_HDIK_V   ?= $(HDIK_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/hdik/.build_complete),)
hdik:
	@echo "Using previously built hdik."
else
hdik:
	mkdir -p $(BUILD_STAGE)/hdik-man/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
ifeq ($(shell [ "$(MEMO_CFVER)" -lt 1600 ] && echo 1),1)
	mkdir -p $(BUILD_STAGE)/hdik/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	$(INSTALL) -m755 $(BUILD_MISC)/hdik/hdik.$(MEMO_CFVER) $(BUILD_STAGE)/hdik/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/hdik
endif
	$(INSTALL) -m644 $(BUILD_MISC)/hdik/hdik.8 $(BUILD_STAGE)/hdik-man/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

hdik-package: hdik-stage
	# hdik.mk Package Structure
	rm -rf $(BUILD_DIST)/hdik{,-man}

	# hdik.mk Prep hdik
ifeq ($(shell [ "$(MEMO_CFVER)" -lt 1600 ] && echo 1),1)
	cp -a $(BUILD_STAGE)/hdik $(BUILD_DIST)
endif
	cp -a $(BUILD_STAGE)/hdik-man $(BUILD_DIST)

ifeq ($(shell [ "$(MEMO_CFVER)" -lt 1600 ] && echo 1),1)
	# hdik.mk Sign hdik
	$(call SIGN,hdik,hdik.xml)
endif

	# hdik.mk Make .debs
ifeq ($(shell [ "$(MEMO_CFVER)" -lt 1600 ] && echo 1),1)
	$(call PACK,hdik,DEB_HDIK_V)
endif
	$(call PACK,hdik-man,DEB_HDIK_V)

	# hdik.mk Build cleanup
	rm -rf $(BUILD_DIST)/hdik{,-man}

.PHONY: hdik hdik-package

endif
