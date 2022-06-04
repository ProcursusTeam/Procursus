ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cmatrix
CMATRIX_VERSION := 2.0
DEB_CMATRIX_V   ?= $(CMATRIX_VERSION)

cmatrix-setup: setup
	$(call GITHUB_ARCHIVE,abishekvashok,cmatrix,$(CMATRIX_VERSION),v$(CMATRIX_VERSION))
	$(call EXTRACT_TAR,cmatrix-$(CMATRIX_VERSION).tar.gz,cmatrix-$(CMATRIX_VERSION),cmatrix)
	mkdir -p $(BUILD_WORK)/cmatrix/build

ifneq ($(wildcard $(BUILD_WORK)/cmatrix/.build_complete),)
cmatrix:
	@echo "Using previously built cmatrix."
else
cmatrix: cmatrix-setup ncurses
	cd $(BUILD_WORK)/cmatrix/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/cmatrix/build
	+$(MAKE) -C $(BUILD_WORK)/cmatrix/build install \
		DESTDIR="$(BUILD_STAGE)/cmatrix"
	$(call AFTER_BUILD)
endif

cmatrix-package: cmatrix-stage
	# cmatrix.mk Package Structure
	rm -rf $(BUILD_DIST)/cmatrix

	# cmatrix.mk Prep cmatrix
	cp -a $(BUILD_STAGE)/cmatrix $(BUILD_DIST)

	# cmatrix.mk Sign
	$(call SIGN,cmatrix,general.xml)

	# cmatrix.mk Make .debs
	$(call PACK,cmatrix,DEB_CMATRIX_V)

	# cmatrix.mk Build cleanup
	rm -rf $(BUILD_DIST)/cmatrix

.PHONY: cmatrix cmatrix-package
