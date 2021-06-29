ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += hexedit
HEXEDIT_VERSION := 1.4
DEB_HEXEDIT_V   ?= $(HEXEDIT_VERSION)

hexedit-setup: setup
	$(call GITHUB_ARCHIVE,pixel,hexedit,$(HEXEDIT_VERSION),$(HEXEDIT_VERSION))
	$(call EXTRACT_TAR,hexedit-$(HEXEDIT_VERSION).tar.gz,hexedit-$(HEXEDIT_VERSION),hexedit)

ifneq ($(wildcard $(BUILD_WORK)/hexedit/.build_complete),)
hexedit:
	@echo "Using previouly built hexedit."
else
hexedit: hexedit-setup ncurses
	cd $(BUILD_WORK)/hexedit && ./autogen.sh && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/hexedit LIBS=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/hexedit install \
		DESTDIR=$(BUILD_STAGE)/hexedit
	touch $(BUILD_WORK)/hexedit/.build_complete
endif

hexedit-package: hexedit-stage
	# hexedit.mk Package Structure
	rm -rf $(BUILD_DIST)/hexedit
	cp -a $(BUILD_STAGE)/hexedit $(BUILD_DIST)

	# hexedit.mk Sign
	$(call SIGN,hexedit,general.xml)

	# hexedit.mk Make .debs
	$(call PACK,hexedit,DEB_HEXEDIT_V)

	# hexedit.mk Build Cleanup
	rm -rf $(BUILD_DIST)/hexedit

.PHONY: hexedit hexedit-package
