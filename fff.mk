ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += fff
fff_VERSION := 2.1
DEB_fff_V   ?= $(fff_VERSION)

fff-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/dylanaraps/fff/archive/$(fff_VERSION).tar.gz
	$(call EXTRACT_TAR,$(fff_VERSION).tar.gz,fff-$(fff_VERSION),fff)

ifneq ($(wildcard $(BUILD_WORK)/fff/.build_complete),)
fff:
	@echo "Using previously built fff."
else
fff: fff-setup
	+$(MAKE) -C $(BUILD_WORK)/fff install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/fff
	touch $(BUILD_WORK)/fff/.build_complete
endif

fff-package: fff-stage
	# fff.mk Package Structure
	rm -rf $(BUILD_DIST)/fff
	
	# fff.mk Prep fff
	cp -a $(BUILD_STAGE)/fff $(BUILD_DIST)
	
	# fff.mk Make .debs
	$(call PACK,fff,DEB_fff_V)
	
	# fff.mk Build cleanup
	rm -rf $(BUILD_DIST)/fff

.PHONY: fff fff-package
