ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += sensible-utils
SENSIBLE-UTILS_VERSION := 0.0.17
DEB_SENSIBLE-UTILS_V   ?= $(SENSIBLE-UTILS_VERSION)-1

sensible-utils-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://deb.debian.org/debian/pool/main/s/sensible-utils/sensible-utils_$(SENSIBLE-UTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,sensible-utils_$(SENSIBLE-UTILS_VERSION).tar.xz,sensible-utils-$(SENSIBLE-UTILS_VERSION),sensible-utils)

ifneq ($(wildcard $(BUILD_WORK)/sensible-utils/.build_complete),)
sensible-utils:
	@echo "Using previously built sensible-utils."
else
sensible-utils: sensible-utils-setup
	cd $(BUILD_WORK)/sensible-utils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/sensible-utils
	+$(MAKE) -C $(BUILD_WORK)/sensible-utils install \
		DESTDIR=$(BUILD_STAGE)/sensible-utils
	$(call AFTER_BUILD)
endif

sensible-utils-package: sensible-utils-stage
	# sensible-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/sensible-utils
	mkdir -p $(BUILD_DIST)/sensible-utils

	# sensible-utils.mk Prep sensible-utils
	cp -a $(BUILD_STAGE)/sensible-utils/ $(BUILD_DIST)/

	# sensible-utils.mk Sign
	$(call SIGN,sensible-utils,general.xml)

	# sensible-utils.mk Make .debs
	$(call PACK,sensible-utils,DEB_SENSIBLE-UTILS_V)

	# sensible-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/sensible-utils

.PHONY: sensible-utils sensible-utils-package
