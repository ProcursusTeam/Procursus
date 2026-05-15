ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += moltenvk
MOLTEN_VK_VERSION := 1.4.1
DEB_MOLTEN_VK_V   ?= $(MOLTEN_VK_VERSION)-3

moltenvk-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,MoltenVK,$(MOLTEN_VK_VERSION),v$(MOLTEN_VK_VERSION))
	$(call EXTRACT_TAR,MoltenVK-$(MOLTEN_VK_VERSION).tar.gz,MoltenVK-$(MOLTEN_VK_VERSION),moltenvk)
	$(call DO_PATCH,moltenvk,moltenvk,-p1)
	mkdir -p $(BUILD_WORK)/moltenvk/build
	$(warning("You need use ios 17+/macos 14+ etc sdk or else build will fail with undeclared identifier errors)
ifneq ($(wildcard $(BUILD_WORK)/moltenvk/.build_complete),)
moltenvk:
	@echo "Using previously built moltenvk."
else

moltenvk: moltenvk-setup cereal vulkan-loader spirv-headers spirv-cross spirv-tools vulkan-volk
	cd $(BUILD_WORK)/moltenvk/build && cmake .. \
		$(DEFAULT_CMAKE_FLAGS) \
		-DMVK_USE_METAL_PRIVATE_API=1 -DMVK_BUILD_SHADER_CONVERTER_TOOL=1 -DMOLTEN_VK_WITH_CCACHE=1 \
		-DCMAKE_OBJCXX_FLAGS="$(CFLAGS)" -DCMAKE_OBJC_FLAGS="$(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/moltenvk/build VERBOSE=1
	+$(MAKE) -C $(BUILD_WORK)/moltenvk/build install \
		DESTDIR="$(BUILD_STAGE)/moltenvk"
	$(call AFTER_BUILD,copy)
endif

moltenvk-package: moltenvk-stage
	# moltenvk.mk Package Structure
	rm -rf $(BUILD_DIST)/moltenvk-bin $(BUILD_DIST)/libmoltenvk{-dev}
	mkdir -p $(BUILD_DIST)/moltenvk-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/libmoltenvk{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# moltenvk.mk Prep moltenvk-bin
	cp -a $(BUILD_STAGE)/moltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/moltenvk-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# moltenvk.mk Prep libmoltenvk
	cp -a $(BUILD_STAGE)/moltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*.dylib $(BUILD_DIST)/libmoltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/moltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc $(BUILD_DIST)/libmoltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# moltenvk.mk Prep libmoltenvk-dev
	cp -a $(BUILD_STAGE)/moltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmoltenvk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/moltenvk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{*.a,pkgconfig} $(BUILD_DIST)/libmoltenvk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib 

	# moltenvk.mk Sign
	$(call SIGN,libmoltenvk,general.xml)
	$(call SIGN,moltenvk-bin,general.xml)

	# moltenvk.mk Make .debs
	$(call PACK,moltenvk-bin,DEB_MOLTEN_VK_V)
	$(call PACK,libmoltenvk,DEB_MOLTEN_VK_V)
	$(call PACK,libmoltenvk-dev,DEB_MOLTEN_VK_V)

	# moltenvk.mk Build cleanup
	rm -rf $(BUILD_DIST)/moltenvk-bin $(BUILD_DIST)/libmoltenvk{,-dev}

.PHONY: moltenvk moltenvk-package
