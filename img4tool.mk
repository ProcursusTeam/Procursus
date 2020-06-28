ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += img4tool
IMG4TOOL_VERSION := 182
DEB_IMG4TOOL_V   ?= $(IMG4TOOL_VERSION)

img4tool-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/img4tool/archive/$(IMG4TOOL_VERSION).tar.gz
	$(call EXTRACT_TAR,$(IMG4TOOL_VERSION).tar.gz,img4tool-$(IMG4TOOL_VERSION),img4tool)
	$(SED) -i 's/libplist /libplist-2.0 /g' $(BUILD_WORK)/img4tool/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/img4tool/.build_complete),)
img4tool:
	@echo "Using previously built img4tool."
else
img4tool: img4tool-setup openssl libplist libgeneral
	cd $(BUILD_WORK)/img4tool && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/img4tool
	+$(MAKE) -C $(BUILD_WORK)/img4tool install \
		DESTDIR="$(BUILD_STAGE)/img4tool"
	+$(MAKE) -C $(BUILD_WORK)/img4tool install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/img4tool/.build_complete
endif

img4tool-package: img4tool-stage
	# img4tool.mk Package Structure
	rm -rf $(BUILD_DIST)/img4tool
	mkdir -p $(BUILD_DIST)/img4tool
	
	# img4tool.mk Prep img4tool
	cp -a $(BUILD_STAGE)/img4tool/usr $(BUILD_DIST)/img4tool
	
	# img4tool.mk Sign
	$(call SIGN,img4tool,general.xml)
	
	# img4tool.mk Make .debs
	$(call PACK,img4tool,DEB_IMG4TOOL_V)
	
	# img4tool.mk Build cleanup
	rm -rf $(BUILD_DIST)/img4tool

.PHONY: img4tool img4tool-package
