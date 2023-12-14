ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gdisk
GDISK_VERSION := 1.0.9
DEB_GDISK_V   ?= $(GDISK_VERSION)

gdisk-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://sourceforge.net/projects/gptfdisk/files/gptfdisk/$(GDISK_VERSION)/gptfdisk-$(GDISK_VERSION).tar.gz)
	$(call EXTRACT_TAR,gptfdisk-$(GDISK_VERSION).tar.gz,gptfdisk-$(GDISK_VERSION),gdisk)
	$(call DO_PATCH,gdisk,gdisk,-p1)

ifneq ($(wildcard $(BUILD_WORK)/gdisk/.build_complete),)
gdisk:
	@echo "Using previously built gdisk."
else
gdisk: gdisk-setup
	# TODO: fix the makefile, it sucks ass
	+$(MAKE) -C $(BUILD_WORK)/gdisk
	+$(MAKE) -C $(BUILD_WORK)/gdisk install \
		DESTDIR=$(BUILD_STAGE)/gdisk
	$(call AFTER_BUILD,copy)
endif

gdisk-package: gdisk-stage
	# gdisk.mk Package Structure
	rm -rf $(BUILD_DIST)/gdisk
	mkdir -p $(BUILD_DIST)/gdisk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# gdisk.mk Sign
	# TODO: This probably needs more entitlements
	$(call SIGN,gdisk,general.xml)

	# gdisk.mk Make .debs
	# TODO: control file
	$(call PACK,gdisk,DEB_GDISK_V)

	# gdisk.mk Build cleanup
	rm -rf $(BUILD_DIST)/gdisk

.PHONY: gdisk gdisk-package
