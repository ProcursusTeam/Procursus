ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += xbattbar
XBATTBAR_VERSION := 1.4.9
DEB_XBATTBAR_V   ?= $(XBATTBAR_VERSION)

xbattbar-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/x/xbattbar/xbattbar_$(XBATTBAR_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,xbattbar_$(XBATTBAR_VERSION).orig.tar.gz,xbattbar-$(XBATTBAR_VERSION),xbattbar)
	wget -q -nc -P$(BUILD_WORK)/xbattbar https://raw.githubusercontent.com/xybp888/iOS-SDKs/master/iPhoneOS14.5.sdk/System/Library/PrivateFrameworks/BatteryCenter.framework/BatteryCenter.tbd
	$(call DO_PATCH,xbattbar,xbattbar,-p1)

ifneq ($(wildcard $(BUILD_WORK)/xbattbar/.build_complete),)
xbattbar:
	@echo "Using previously built xbattbar."
else
xbattbar: libx11 xbattbar-setup
	$(MAKE) -C $(BUILD_WORK)/xbattbar
	+$(MAKE) -C $(BUILD_WORK)/xbattbar install \
		DESTDIR=$(BUILD_STAGE)/xbattbar
	$(call AFTER_BUILD)
endif

xbattbar-package: xbattbar-stage
	# xbattbar.mk Package Structure
	rm -rf $(BUILD_DIST)/xbattbar
	
	# xbattbar.mk Prep xbattbar
	cp -a $(BUILD_STAGE)/xbattbar $(BUILD_DIST)
	
	# xbattbar.mk Sign
	$(call SIGN,xbattbar,general.xml)
	
	# xbattbar.mk Make .debs
	$(call PACK,xbattbar,DEB_XBATTBAR_V)
	
	# xbattbar.mk Build cleanup
	rm -rf $(BUILD_DIST)/xbattbar

.PHONY: xbattbar xbattbar-package
