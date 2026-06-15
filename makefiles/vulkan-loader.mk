ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += vulkan-loader
VULKAN_LOADER_VERSION := 1.4.348
DEB_VULKAN_LOADER_V   ?= $(VULKAN_LOADER_VERSION)

SUBPROJECTS   += vulkan-headers
VULKAN_HEADERS_VERSION := $(VULKAN_LOADER_VERSION)

vulkan-headers-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,Vulkan-Headers,v$(VULKAN_HEADERS_VERSION),v$(VULKAN_HEADERS_VERSION))
	$(call EXTRACT_TAR,Vulkan-Headers-v$(VULKAN_HEADERS_VERSION).tar.gz,Vulkan-Headers-$(VULKAN_HEADERS_VERSION),vulkan-headers)
	mkdir -p $(BUILD_WORK)/vulkan-headers/build

vulkan-loader-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,Vulkan-Loader,v$(VULKAN_LOADER_VERSION),v$(VULKAN_LOADER_VERSION))
	$(call EXTRACT_TAR,Vulkan-Loader-v$(VULKAN_LOADER_VERSION).tar.gz,Vulkan-Loader-$(VULKAN_LOADER_VERSION),vulkan-loader)
	mkdir -p $(BUILD_WORK)/vulkan-loader/build
	$(call DO_PATCH,vulkan-loader,vulkan-loader,-p1)

ifneq ($(wildcard $(BUILD_WORK)/vulkan-headers/.build_complete),)
vulkan-headers:
	@echo "Using previously built vulkan-headers."
else
vulkan-headers: vulkan-headers-setup
	cd $(BUILD_WORK)/vulkan-headers/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) 

	+$(MAKE) -C $(BUILD_WORK)/vulkan-headers/build
	+$(MAKE) -C $(BUILD_WORK)/vulkan-headers/build install \
		DESTDIR="$(BUILD_STAGE)/vulkan-headers"
	$(call AFTER_BUILD,copy)
endif
ifneq ($(wildcard $(BUILD_WORK)/vulkan-loader/.build_complete),)
vulkan-loader:
	@echo "Using previously built vulkan-loader."
else
vulkan-loader: vulkan-headers-setup vulkan-loader-setup vulkan-headers libxrandr libxcb libx11
	cd $(BUILD_WORK)/vulkan-loader/build && cmake .. \
		-DFALLBACK_CONFIG_DIRS="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc/xdg" \
		-DFALLBACK_CONFIG_DIRS="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/share" \
		-DBUILD_WSI_WAYLAND_SUPPORT=0 -DBUILD_TESTS=0 \
		$(VULKAN_LOADER_CMAKE_FLAGS) \
		$(DEFAULT_CMAKE_FLAGS)

	+$(MAKE) -C $(BUILD_WORK)/vulkan-loader/build VERBOSE=1
	+$(MAKE) -C $(BUILD_WORK)/vulkan-loader/build install \
		DESTDIR="$(BUILD_STAGE)/vulkan-loader" VERBOSE=1
	$(call AFTER_BUILD,copy)
endif

vulkan-loader-package: vulkan-loader-stage
	# vulkan-loader.mk Package Structure
	rm -rf $(BUILD_DIST)/libvulkan{1,dev}
	mkdir -p $(BUILD_DIST)/libvulkan{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# vulkan-loader.mk Prep libvulkan1
	cp -a $(BUILD_STAGE)/vulkan-loader/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{loader,lib/*.dylib}  $(BUILD_DIST)/libvulkan1$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# vulkan-loader.mk Prep libvulkan-dev
	cp -a $(BUILD_STAGE)/vulkan-headers/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libvulkan-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/vulkan-loader/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{cmake,pkgconfig} $(BUILD_DIST)/libvulkan-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# vulkan-loader.mk Sign
	$(call SIGN,libvulkan1,general.xml)

	# vulkan-loader.mk Make .debs
	$(call PACK,libvulkan1,DEB_VULKAN_LOADER_V)
	$(call PACK,libvulkan-dev,DEB_VULKAN_LOADER_V)

	# vulkan-loader.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvulkan{1,dev}

.PHONY: vulkan-headers vulkan-loader vulkan-loader-package
