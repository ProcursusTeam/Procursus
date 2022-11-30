ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mold
MOLD_VERSION := 1.7.1
DEB_MOLD_V   ?= $(MOLD_VERSION)

mold-setup: setup
	$(call GITHUB_ARCHIVE,rui314,mold,$(MOLD_VERSION),v$(MOLD_VERSION))
	$(call EXTRACT_TAR,mold-$(MOLD_VERSION).tar.gz,mold-$(MOLD_VERSION),mold)
	mkdir -p $(BUILD_WORK)/mold/build

ifneq ($(wildcard $(BUILD_WORK)/mold/.build_complete),)
mold:
	@echo "Using previously built mold."
else
mold: mold-setup
	cd $(BUILD_WORK)/mold/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/mold/build
	+$(MAKE) -C $(BUILD_WORK)/mold/build install \
		DESTDIR="$(BUILD_STAGE)/mold"
	$(call AFTER_BUILD)
endif

mold-package: mold-stage
	# mold.mk Package Structure
	rm -rf $(BUILD_DIST)/mold

	# mold.mk Prep mold
	cp -a $(BUILD_STAGE)/mold $(BUILD_DIST)

	# mold.mk Sign
	$(call SIGN,mold,general.xml)

	# mold.mk Make .debs
	$(call PACK,mold,DEB_MOLD_V)

	# mold.mk Build cleanup
	rm -rf $(BUILD_DIST)/mold

.PHONY: mold mold-package
