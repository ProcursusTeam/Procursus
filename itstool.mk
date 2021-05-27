ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += itstool
ITSTOOL_VERSION := 2.0.6
DEB_ITSTOOL_V   ?= $(ITSTOOL_VERSION)

itstool-setup: setup
	$(call GITHUB_ARCHIVE,itstool,itstool,$(ITSTOOL_VERSION),$(ITSTOOL_VERSION))
	$(call EXTRACT_TAR,itstool-$(ITSTOOL_VERSION).tar.gz,itstool-$(ITSTOOL_VERSION),itstool)

ifneq ($(wildcard $(BUILD_WORK)/itstool/.build_complete),)
itstool:
	@echo "Using previously built itstool."
else
itstool: itstool-setup
	cd $(BUILD_WORK)/itstool && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		PYTHON=python3
	+$(MAKE) -C $(BUILD_WORK)/itstool install \
		DESTDIR=$(BUILD_STAGE)/itstool
	$(SED) -i "s|#!python3|#!$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/itstool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/itstool
	touch $(BUILD_WORK)/itstool/.build_complete
endif

itstool-package: itstool-stage
	# itstool.mk Package Structure
	rm -rf $(BUILD_DIST)/itstool
	
	# itstool.mk Prep itstool
	cp -a $(BUILD_STAGE)/itstool $(BUILD_DIST)
	
	# itstool.mk Sign
	$(call SIGN,itstool,general.xml)
	
	# itstool.mk Make .debs
	$(call PACK,itstool,DEB_ITSTOOL_V)
	
	# itstool.mk Build cleanup
	rm -rf $(BUILD_DIST)/itstool

.PHONY: itstool itstool-package
