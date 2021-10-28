ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
SUBPROJECTS           += darling-utils
DARLING_COMMIT        := 9393db2c6ed530acaa2a4a933c391f1363fea1e8
DARLING_UTILS_VERSION := 2021.08.01
DEB_DARLING_UTILS_V   ?= $(DARLING_UTILS_VERSION)

darling-utils-setup: setup
	$(call GITHUB_ARCHIVE,darlinghq,darling,$(DARLING_COMMIT),$(DARLING_COMMIT))
	$(call EXTRACT_TAR,darling-$(DARLING_COMMIT).tar.gz,darling-$(DARLING_COMMIT),darling-utils)
	mkdir -p $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec,share/man/man8}

ifneq ($(wildcard $(BUILD_WORK)/darling-utils/.build_complete),)
darling-utils:
	@echo "Using previously built darling-utils."
else
darling-utils: darling-utils-setup xar
	cd $(BUILD_WORK)/darling-utils/src/unxip; \
		$(CC) $(CFLAGS) $(LDFLAGS) -lxar -llzma xip_extract_cpio.c -o $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/xip_extract_cpio; \
	sed 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' unxip > $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/unxip
	chmod +x $(BUILD_STAGE)/darling-utils/$(MEMO_PREFUX)$(MEMO_SUB_PREFIX)/bin/unxip
	cd $(BUILD_WORK)/darling-utils/src/PlistBuddy; \
		$(CC) $(CFLAGS) $(LDFLAGS) PlistBuddy.c -framework CoreFoundation -o $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/PlistBuddy; \
		install -m644 PlistBuddy.8 $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

darling-utils-package: darling-utils-stage
	# darling-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/{unxip,plistbuddy}
	mkdir -p $(BUILD_DIST)/{unxip,plistbuddy}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	
	# darling-utils.mk Prep unxip
	cp -a $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/xip_extract_cpio $(BUILD_DIST)/unxip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/unxip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# darling-utils.mk Prep plistbuddy
	cp -a $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/PlistBuddy $(BUILD_DIST)/plistbuddy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/darling-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/plistbuddy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# darling-utils.mk Sign
	$(call SIGN,unxip,general.xml)
	$(call SIGN,plistbuddy,general.xml)
	
	# darling-utils.mk Make .debs
	$(call PACK,unxip,DEB_DARLING_UTILS_V)
	$(call PACK,plistbuddy,DEB_DARLING_UTILS_V)
	
	# darling-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/{unxip,plistbuddy}

.PHONY: darling-utils darling-utils-package
endif
