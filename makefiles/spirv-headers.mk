ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += spirv-headers
SPIRV_HEADERS_VERSION := 1.4.341
DEB_SPIRV_HEADERS_V   ?= $(SPIRV_HEADERS_VERSION)

spirv-headers-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,SPIRV-Headers,vulkan-sdk-$(SPIRV_HEADERS_VERSION),vulkan-sdk-$(SPIRV_HEADERS_VERSION))
	$(call EXTRACT_TAR,SPIRV-Headers-vulkan-sdk-$(SPIRV_HEADERS_VERSION).tar.gz,SPIRV-Headers-vulkan-sdk-$(SPIRV_HEADERS_VERSION),spirv-headers)
	mkdir -p $(BUILD_WORK)/spirv-headers/build

ifneq ($(wildcard $(BUILD_WORK)/spirv-headers/.build_complete),)
spirv-headers:
	@echo "Using previously built spirv-headers."
else
spirv-headers: spirv-headers-setup
	cd $(BUILD_WORK)/spirv-headers/build && cmake .. \
	-DSPIRV_HEADERS_ENABLE_TESTS=0 $(DEFAULT_CMAKE_FLAGS)

	+$(MAKE) -C $(BUILD_WORK)/spirv-headers/build
	+$(MAKE) -C $(BUILD_WORK)/spirv-headers/build install \
		DESTDIR="$(BUILD_STAGE)/spirv-headers"
	$(call AFTER_BUILD,copy)
endif

spirv-headers-package: spirv-headers-stage
	# spirv-headers.mk Package Structure
	rm -rf $(BUILD_DIST)/libspirv-headers-dev
	mkdir -p $(BUILD_DIST)/libspirv-headers-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# spirv-headers.mk Prep libspirv-headers-dev
	cp -a $(BUILD_STAGE)/spirv-headers$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/libspirv-headers-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# spirv-headers.mk Make .debs
	$(call PACK,libspirv-headers-dev,DEB_SPIRV_HEADERS_V)

	# spirv-headers.mk Build cleanup
	rm -rf $(BUILD_DIST)/libspirv-headers-dev

.PHONY: spirv-headers spirv-headers-package
