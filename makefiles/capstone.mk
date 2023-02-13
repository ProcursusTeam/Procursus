ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += capstone
CAPSTONE_VERSION := 4.0.2
DEB_CAPSTONE_V   ?= $(CAPSTONE_VERSION)

capstone-setup: setup
	$(call GITHUB_ARCHIVE,capstone-engine,capstone,$(CAPSTONE_VERSION),$(CAPSTONE_VERSION))
	$(call EXTRACT_TAR,capstone-$(CAPSTONE_VERSION).tar.gz,capstone-$(CAPSTONE_VERSION),capstone)
	$(call DO_PATCH,capstone,capstone,-p1)

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
		$(BUILD_DIST)/libcapstone{4,-dev}
	mkdir -p $(BUILD_DIST)/libcapstone4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} \
		$(BUILD_DIST)/capstone-tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# capstone.mk Prep libcapstone4
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcapstone.4.dylib $(BUILD_DIST)/libcapstone4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# capstone.mk Prep libcapstone-dev
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcapstone.{dylib,a},pkgconfig} $(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ $(BUILD_DIST)/libcapstone-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# capstone.mk Prep capstone-tool
	cp -a $(BUILD_STAGE)/capstone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/capstone-tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# capstone.mk Sign
	$(call SIGN,libcapstone4,general.xml)
	$(call SIGN,capstone-tool,general.xml)

	# capstone.mk Make .debs
	$(call PACK,libcapstone4,DEB_CAPSTONE_V)
	$(call PACK,libcapstone-dev,DEB_CAPSTONE_V)
	$(call PACK,capstone-tool,DEB_CAPSTONE_V)

	# capstone.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcapstone{4,-dev} $(BUILD_DIST)/capstone-tool

.PHONY: capstone capstone-package
