ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += vulkan-volk
VULKAN_VOLK_VERSION := 1.4.348
DEB_VULKAN_VOLK_V   ?= $(VULKAN_VOLK_VERSION)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	VULKAN_VOLK_CMAKE_FLAGS := -DVK_USE_PLATFORM_MACOS_MVK
else
	VULKAN_VOLK_CMAKE_FLAGS := -DVK_USE_PLATFORM_IOS_MVK
endif

vulkan-volk-setup: setup
	$(call GITHUB_ARCHIVE,zeux,volk,vulkan-sdk-$(VULKAN_VOLK_VERSION),vulkan-sdk-$(VULKAN_VOLK_VERSION))
	$(call EXTRACT_TAR,volk-vulkan-sdk-$(VULKAN_VOLK_VERSION).tar.gz,volk-vulkan-sdk-$(VULKAN_VOLK_VERSION),vulkan-volk)
	mkdir -p $(BUILD_WORK)/vulkan-volk/build

ifneq ($(wildcard $(BUILD_WORK)/vulkan-volk/.build_complete),)
vulkan-volk:
	@echo "Using previously built vulkan-volk."
else
vulkan-volk: vulkan-volk-setup vulkan-loader libx11 libxcb libxrandr
	cd $(BUILD_WORK)/vulkan-volk/build && cmake .. \
		-DVOLK_INSTALL=ON -DVULKAN_HEADERS_INSTALL_DIR="$(BUILD_STAGE)/vulkan-volk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		-DVOLK_STATIC_DEFINES="-DVK_USE_PLATFORM_XCB_KHR -DVK_USE_PLATFORM_XLIB_KHR -DVK_USE_PLATFORM_XLIB_XRANDR_EXT \
		-DVK_ENABLE_BETA_EXTENSIONS -DVK_USE_PLATFORM_METAL_EXT $(VULKAN_VOLK_CMAKE_FLAGS)" \
		$(DEFAULT_CMAKE_FLAGS)

	+$(MAKE) -C $(BUILD_WORK)/vulkan-volk/build
	+$(MAKE) -C $(BUILD_WORK)/vulkan-volk/build install \
		DESTDIR="$(BUILD_STAGE)/vulkan-volk"
	$(call AFTER_BUILD,copy)
endif

vulkan-volk-package: vulkan-volk-stage
	# vulkan-volk.mk Package Structure
	rm -rf $(BUILD_DIST)/libvulkan-volk-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libvulkan-volk-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# vulkan-volk.mk Prep libvulkan-volk-dev
	cp -ar $(BUILD_STAGE)/vulkan-volk$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/libvulkan-volk-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# vulkan-volk.mk Make .debs
	$(call PACK,libvulkan-volk-dev,DEB_VULKAN_VOLK_V)

	# vulkan-volk.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvulkan-volk-dev

.PHONY: vulkan-volk vulkan-volk-package
