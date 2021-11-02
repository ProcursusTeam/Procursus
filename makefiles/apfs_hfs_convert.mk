ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPPROJECTS             += apfs_hfs_convert
APFS_HFS_CONVERT_VERSION := $(shell $(STRINGS) $(BUILD_MISC)/apfs_hfs_convert/apfs_hfs_convert.$(MEMO_CFVER) | grep apfs_executables/apfs | head -n 1 | cut -d- -f2  | cut -d/ -f1)
DEB_APFS_HFS_CONVERT_V   ?= $(APFS_HFS_CONVERT_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/apfs_hfs_convert/.build_complete),)
apfs_hfs_convert:
	@echo "Using previously built apfs_hfs_convert."
else
apfs_hfs_convert:
	mkdir -p $(BUILD_STAGE)/apfs_hfs_convert/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/man8},$(MEMO_PREFIX)/sbin}
	$(INSTALL) -m755 $(BUILD_MISC)/apfs_hfs_convert/apfs_hfs_convert.$(MEMO_CFVER) $(BUILD_STAGE)/apfs_hfs_convert/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/apfs_hfs_convert
ifneq ($(MEMO_SUB_PREFIX),)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/apfs_hfs_convert $(BUILD_STAGE)/apfs_hfs_convert/$(MEMO_PREFIX)/sbin/apfs_hfs_convert
endif
	$(INSTALL) -m644 $(BUILD_MISC)/apfs_hfs_convert/apfs_hfs_convert.8 $(BUILD_STAGE)/apfs_hfs_convert/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

apfs_hfs_convert-package: apfs_hfs_convert-stage
	# apfs_hfs_convert.mk Package Structure
	rm -rf $(BUILD_DIST)/apfs_hfs_convert

	# apfs_hfs_convert.mk Prep apfs_hfs_convert
	cp -a $(BUILD_STAGE)/apfs_hfs_convert $(BUILD_DIST)

	# apfs_hfs_convert.mk Sign apfs_hfs_convert
	$(call SIGN,apfs_hfs_convert,dd.xml)

	# apfs_hfs_convert.mk Make .debs
	$(call PACK,apfs_hfs_convert,DEB_APFS_HFS_CONVERT_V)

	# apfs_hfs_convert.mk Build cleanup
	rm -rf $(BUILD_DIST)/apfs_hfs_convert

.PHONY: apfs_hfs_convert apfs_hfs_convert-package

endif
