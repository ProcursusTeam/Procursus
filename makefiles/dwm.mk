ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += dwm
DWM_VERSION := 6.2
DEB_DWM_V   ?= $(DWM_VERSION)

dwm-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://dl.suckless.org/dwm/dwm-6.2.tar.gz
	$(call EXTRACT_TAR,dwm-$(DWM_VERSION).tar.gz,dwm-$(DWM_VERSION),dwm)
	$(call DO_PATCH,dwm,dwm,-p1)

ifneq ($(wildcard $(BUILD_WORK)/dwm/.build_complete),)
dwm:
	@echo "Using previously built dwm."
else
dwm: libx11 libxft fontconfig freetype libxinerama dwm-setup
	$(MAKE) -C $(BUILD_WORK)/dwm
	$(MAKE) -C $(BUILD_WORK)/dwm install \
		DESTDIR=$(BUILD_STAGE)/dwm
	touch $(BUILD_WORK)/dwm/.build_complete
endif

dwm-package: dwm-stage
	# dwm.mk Package Structure
	rm -rf $(BUILD_DIST)/dwm
	mkdir -p $(BUILD_DIST)/dwm
	
	# dwm.mk Prep dwm
	cp -a $(BUILD_STAGE)/dwm $(BUILD_DIST)
	
	# dwm.mk Sign
	$(call SIGN,dwm,general.xml)
	
	# dwm.mk Make .debs
	$(call PACK,dwm,DEB_DWM_V)
	
	# dwm.mk Build cleanup
	rm -rf $(BUILD_DIST)/dwm

.PHONY: dwm dwm-package
