ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += xbattbar
XBATTBAR_VERSION := 1.4.2
DEB_XBATTBAR_V   ?= $(XBATTBAR_VERSION)

xbattbar-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://salsa.debian.org/debian/xbattbar/-/archive/master/xbattbar-master.tar.bz2
	$(call EXTRACT_TAR,xbattbar-master.tar.bz2,xbattbar-master,xbattbar)
	$(call DO_PATCH,xbattbar,xbattbar,-p1)
	$(SED) -i 's|@MEMO_PREFIX@@MEMO_SUB_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_WORK)/xbattbar/xbattbar.c

ifneq ($(wildcard $(BUILD_WORK)/xbattbar/.build_complete),)
xbattbar:
	@echo "Using previously built xbattbar."
else
xbattbar: libx11 xbattbar-setup
	$(MAKE) -C $(BUILD_WORK)/xbattbar
	$(MAKE) -C $(BUILD_WORK)/xbattbar install \
		DESTDIR=$(BUILD_STAGE)/xbattbar
	touch $(BUILD_WORK)/xbattbar/.build_complete
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
