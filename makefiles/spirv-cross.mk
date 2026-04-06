ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += spirv-cross
SPIRV_CROSS_VERSION := 1.4.341
DEB_SPIRV_CROSS_V   ?= $(SPIRV_CROSS_VERSION)

spirv-cross-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,SPIRV-Cross,vulkan-sdk-$(SPIRV_CROSS_VERSION),vulkan-sdk-$(SPIRV_CROSS_VERSION))
	$(call EXTRACT_TAR,SPIRV-Cross-vulkan-sdk-$(SPIRV_CROSS_VERSION).tar.gz,SPIRV-Cross-vulkan-sdk-$(SPIRV_CROSS_VERSION),spirv-cross)
	mkdir -p $(BUILD_WORK)/spirv-cross/build

ifneq ($(wildcard $(BUILD_WORK)/spirv-cross/.build_complete),)
spirv-cross:
	@echo "Using previously built spirv-cross."
else
spirv-cross: spirv-cross-setup
	cd $(BUILD_WORK)/spirv-cross/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) \
		-DSPIRV_CROSS_SHARED=1 -DSPIRV_CROSS_ENABLE_TESTS=0

	+$(MAKE) -C $(BUILD_WORK)/spirv-cross/build
	+$(MAKE) -C $(BUILD_WORK)/spirv-cross/build install \
		DESTDIR="$(BUILD_STAGE)/spirv-cross"
	$(call AFTER_BUILD,copy)
endif

spirv-cross-package: spirv-cross-stage
	# spirv-cross.mk Package Structure
	rm -rf $(BUILD_DIST)/{lib,}spirv-cross{-bin,-c-shared0{-dev,}}
	mkdir -p $(BUILD_DIST)/spirv-cross-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libspirv-cross-c-shared0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	mkdir -p $(BUILD_DIST)/libspirv-cross-c-shared0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# spirv-cross.mk Prep spirv-cross-bin
	cp -a $(BUILD_STAGE)/spirv-cross/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/spirv-cross-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# spirv-cross.mk Prep libspirv-cross-c-shared0-dev
	cp -a $(BUILD_STAGE)/spirv-cross/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libspirv-cross-c-shared0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/spirv-cross/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{*.a,pkgconfig} $(BUILD_DIST)/libspirv-cross-c-shared0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/spirv-cross/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libspirv-cross-c-shared0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# spirv-cross.mk Prep libspirv-cross-c-shared0
	cp -a $(BUILD_STAGE)/spirv-cross/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*.dylib $(BUILD_DIST)/libspirv-cross-c-shared0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# spirv-cross.mk Sign
	$(call SIGN,spirv-cross-bin,general.xml)
	$(call SIGN,libspirv-cross-c-shared0,general.xml)

	# spirv-cross.mk Make .debs
	$(call PACK,spirv-cross-bin,DEB_SPIRV_CROSS_V)
	$(call PACK,libspirv-cross-c-shared0,DEB_SPIRV_CROSS_V)
	$(call PACK,libspirv-cross-c-shared0-dev,DEB_SPIRV_CROSS_V)

	# spirv-cross.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lib,}spirv-cross{-bin,-c-shared0{-dev,}}

.PHONY: spirv-cross spirv-cross-package
