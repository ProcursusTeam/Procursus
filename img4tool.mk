ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += img4tool
IMG4TOOL_VERSION := 193
DEB_IMG4TOOL_V   ?= $(IMG4TOOL_VERSION)

img4tool-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/img4tool/archive/$(IMG4TOOL_VERSION).tar.gz
	$(call EXTRACT_TAR,$(IMG4TOOL_VERSION).tar.gz,img4tool-$(IMG4TOOL_VERSION),img4tool)

ifneq ($(wildcard $(BUILD_WORK)/img4tool/.build_complete),)
img4tool:
	@echo "Using previously built img4tool."
else
img4tool: img4tool-setup openssl libplist libgeneral
	cd $(BUILD_WORK)/img4tool && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/img4tool
	+$(MAKE) -C $(BUILD_WORK)/img4tool install \
		DESTDIR="$(BUILD_STAGE)/img4tool"
	+$(MAKE) -C $(BUILD_WORK)/img4tool install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/img4tool/.build_complete
endif

img4tool-package: img4tool-stage
	# img4tool.mk Package Structure
	rm -rf $(BUILD_DIST)/*img4tool*/
	mkdir -p $(BUILD_DIST)/{img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,libimg4tool0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,libimg4tool-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}}
	
	# img4tool.mk Prep img4tool
	cp -a $(BUILD_STAGE)/img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/img4tool $(BUILD_DIST)/img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# img4tool.mk Prep libimg4tool0
	cp -a $(BUILD_STAGE)/img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libimg4tool.0.dylib $(BUILD_DIST)/libimg4tool0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# img4tool.mk Prep libimg4tool-dev
	cp -a $(BUILD_STAGE)/img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libimg4tool.dylib,pkgconfig} $(BUILD_DIST)/libimg4tool-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/img4tool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/img4tool $(BUILD_DIST)/libimg4tool-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# img4tool.mk Sign
	$(call SIGN,img4tool,general.xml)
	$(call SIGN,libimg4tool0,general.xml)

	# img4tool.mk Make .debs
	$(call PACK,img4tool,DEB_IMG4TOOL_V)
	$(call PACK,libimg4tool0,DEB_IMG4TOOL_V)
	$(call PACK,libimg4tool-dev,DEB_IMG4TOOL_V)

	# img4tool.mk Build cleanup
	rm -rf $(BUILD_DIST)/*img4tool*/

.PHONY: img4tool img4tool-package
