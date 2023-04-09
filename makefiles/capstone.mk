ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += capstone
CAPSTONE_COMMIT  := 6e6e602e3815c48270ea1c1b0399302800dd3132
CAPSTONE_VERSION := 5.0~git20230223.$(shell echo $(CAPSTONE_COMMIT) | cut -c -7)
DEB_CAPSTONE_V   ?= $(CAPSTONE_VERSION)

capstone-setup: setup
	$(call GITHUB_ARCHIVE,capstone-engine,capstone,$(CAPSTONE_COMMIT),$(CAPSTONE_COMMIT))
	$(call EXTRACT_TAR,capstone-$(CAPSTONE_COMMIT).tar.gz,capstone-$(CAPSTONE_COMMIT),capstone)

ifneq ($(wildcard $(BUILD_WORK)/capstone/.build_complete),)
capstone:
	@echo "Using previously built capstone."
else
capstone: capstone-setup
	+$(MAKE) -C $(BUILD_WORK)/capstone \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		LIBARCHS="$(MEMO_ARCH)"
	+$(MAKE) -C $(BUILD_WORK)/capstone install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR=$(BUILD_STAGE)/capstone
	$(call AFTER_BUILD,copy)
endif

capstone-package: capstone-stage
	# capstone.mk Package Structure
	rm -rf $(BUILD_DIST)/capstone-tool \
		$(BUILD_DIST)/libcapstone{5,-dev}
	mkdir -p $(BUILD_DIST)/libcapstone5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} \
		$(BUILD_DIST)/capstone-tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# capstone.mk Prep libcapstone5
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcapstone.5.dylib $(BUILD_DIST)/libcapstone5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# capstone.mk Prep libcapstone-dev
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcapstone.{dylib,a},pkgconfig} $(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ $(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# capstone.mk Prep capstone-tool
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/capstone-tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# capstone.mk Sign
	$(call SIGN,libcapstone5,general.xml)
	$(call SIGN,capstone-tool,general.xml)

	# capstone.mk Make .debs
	$(call PACK,libcapstone5,DEB_CAPSTONE_V)
	$(call PACK,libcapstone-dev,DEB_CAPSTONE_V)
	$(call PACK,capstone-tool,DEB_CAPSTONE_V)

	# capstone.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcapstone{5,-dev} $(BUILD_DIST)/capstone-tool

.PHONY: capstone capstone-package
