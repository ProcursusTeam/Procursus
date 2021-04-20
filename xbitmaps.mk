ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += xbitmaps
XBITMAPS_VERSION := 1.1.0
DEB_XBITMAPS_V   ?= $(XBITMAPS_VERSION)

xbitmaps-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/app/xbitmaps-$(XBITMAPS_VERSION).tar.gz
	$(call EXTRACT_TAR,xbitmaps-$(XBITMAPS_VERSION).tar.gz,xbitmaps-$(XBITMAPS_VERSION),xbitmaps)

ifneq ($(wildcard $(BUILD_WORK)/xbitmaps/.build_complete),)
xbitmaps:
	@echo "Using previously built xbitmaps."
else
xbitmaps: xbitmaps-setup xorgproto
	cd $(BUILD_WORK)/xbitmaps && autoreconf -fiv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xbitmaps
	+$(MAKE) -C $(BUILD_WORK)/xbitmaps install \
		DESTDIR=$(BUILD_STAGE)/xbitmaps
	+$(MAKE) -C $(BUILD_WORK)/xbitmaps install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xbitmaps/.build_complete
endif

xbitmaps-package: xbitmaps-stage
# xbitmaps.mk Package Structure
	rm -rf $(BUILD_DIST)/xbitmaps
	
# xbitmaps.mk Prep xbitmaps
	cp -a $(BUILD_STAGE)/xbitmaps $(BUILD_DIST)
	
# xbitmaps.mk Make .debs
	$(call PACK,xbitmaps,DEB_XBITMAPS_V)
	
# xbitmaps.mk Build cleanup
	rm -rf $(BUILD_DIST)/xbitmaps

.PHONY: xbitmaps xbitmaps-package
