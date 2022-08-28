ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += iodine
IODINE_VERSION := df49fd6
DEB_IODINE_V   ?= $(IODINE_VERSION)

IODINE_COMMIT  := df49fd6f3d9030662374bfbdcca3e74327084f5e

iodine-setup: setup
	$(call GITHUB_ARCHIVE,yarrick,iodine,$(IODINE_VERSION),$(IODINE_COMMIT))
	$(call EXTRACT_TAR,iodine-$(IODINE_VERSION).tar.gz,iodine-$(IODINE_COMMIT),iodine)

ifneq ($(wildcard $(BUILD_WORK)/iodine/.build_complete),)
iodine:
	@echo "Using previously built iodine."
else
iodine: iodine-setup
	cd $(BUILD_WORK)/iodine
	+$(MAKE) -C $(BUILD_WORK)/iodine TARGETOS=Darwin
	+$(MAKE) -C $(BUILD_WORK)/iodine install \
		DESTDIR="$(BUILD_STAGE)/iodine"
	$(call AFTER_BUILD)
endif

iodine-package: iodine-stage
	# iodine.mk Package Structure
	rm -rf $(BUILD_DIST)/iodine

	# iodine.mk Prep iodine
	cp -a $(BUILD_STAGE)/iodine $(BUILD_DIST)

	# iodine.mk Sign
	$(call SIGN,iodine,general.xml)

	# iodine.mk Make .debs
	$(call PACK,iodine,DEB_IODINE_V)

	# iodine.mk Build cleanup
	rm -rf $(BUILD_DIST)/iodine

.PHONY: iodine iodine-package
