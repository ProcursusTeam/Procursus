ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += fff
FFF_VERSION := 2.2
DEB_FFF_V   ?= $(FFF_VERSION)

fff-setup: setup
	$(call GITHUB_ARCHIVE,dylanaraps,fff,$(FFF_VERSION),$(FFF_VERSION))
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/dylanaraps/fff/archive/$(FFF_VERSION).tar.gz
	$(call EXTRACT_TAR,fff-$(FFF_VERSION).tar.gz,fff-$(FFF_VERSION),fff)

ifneq ($(wildcard $(BUILD_WORK)/fff/.build_complete),)
fff:
	@echo "Using previously built fff."
else
fff: fff-setup
	+$(MAKE) -C $(BUILD_WORK)/fff install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/fff
	touch $(BUILD_WORK)/fff/.build_complete
endif

fff-package: fff-stage
	# fff.mk Package Structure
	rm -rf $(BUILD_DIST)/fff

	# fff.mk Prep fff
	cp -a $(BUILD_STAGE)/fff $(BUILD_DIST)

	# fff.mk Make .debs
	$(call PACK,fff,DEB_FFF_V)

	# fff.mk Build cleanup
	rm -rf $(BUILD_DIST)/fff

.PHONY: fff fff-package
