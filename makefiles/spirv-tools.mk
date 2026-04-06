ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += spirv-tools
SPIRV_TOOLS_VERSION := 2026.1
DEB_SPIRV_TOOLS_V   ?= $(SPIRV_TOOLS_VERSION)

spirv-tools-setup: setup
	$(call GITHUB_ARCHIVE,KhronosGroup,SPIRV-Tools,v$(SPIRV_TOOLS_VERSION),v$(SPIRV_TOOLS_VERSION))
	$(call EXTRACT_TAR,SPIRV-Tools-v$(SPIRV_TOOLS_VERSION).tar.gz,SPIRV-Tools-$(SPIRV_TOOLS_VERSION),spirv-tools)
	mkdir -p $(BUILD_WORK)/spirv-tools/build
	sed -i -e 's/SPIRV-Headers_SOURCE_DIR/SPIRV_HEADER_DIR/g' $(BUILD_WORK)/spirv-tools/external/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/spirv-tools/.build_complete),)
spirv-tools:
	@echo "Using previously built spirv-tools."
else
spirv-tools: spirv-tools-setup spirv-headers
	cd $(BUILD_WORK)/spirv-tools/build && cmake .. \
		-DSPIRV_SKIP_TESTS=1 -DBUILD_SHARED_LIBS=1 -DSPIRV_WERROR=0 \
		-DSPIRV_HEADER_DIR="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		$(DEFAULT_CMAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/spirv-tools/build
	+$(MAKE) -C $(BUILD_WORK)/spirv-tools/build install \
		DESTDIR="$(BUILD_STAGE)/spirv-tools"
	$(call AFTER_BUILD,copy)
endif

spirv-tools-package: spirv-tools-stage
	# spirv-tools.mk Package Structure
	rm -rf $(BUILD_DIST)/spirv-tools-bin $(BUILD_DIST)/libspirv-tools0{-dev}
	mkdir -p $(BUILD_DIST)/spirv-tools-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/libspirv-tools0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# spirv-tools.mk Prep spirv-tools-bin
	cp -a $(BUILD_STAGE)/spirv-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/spirv-tools-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

        # spirv-tools.mk Prep libspirv-tools0-dev
	cp -a $(BUILD_STAGE)/spirv-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libspirv-tools0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/spirv-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{*.a,cmake,pkgconfig} $(BUILD_DIST)/libspirv-tools0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# spirv-tools.mk Prep libspirv-tools0
	cp -a $(BUILD_STAGE)/spirv-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*.dylib $(BUILD_DIST)/libspirv-tools0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# spirv-tools.mk Sign
	$(call SIGN,spirv-tools-bin,general.xml)
	$(call SIGN,libspirv-tools0,general.xml)

	# spirv-tools.mk Make .debs
	$(call PACK,spirv-tools-bin,DEB_SPIRV_TOOLS_V)
	$(call PACK,libspirv-tools0-dev,DEB_SPIRV_TOOLS_V)
	$(call PACK,libspirv-tools0,DEB_SPIRV_TOOLS_V)


	# spirv-tools.mk Build cleanup
	rm -rf $(BUILD_DIST)/spirv-tools $(BUILD_DIST)/libspirv-tools0{-dev}

.PHONY: spirv-tools spirv-tools-package
