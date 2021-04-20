ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xwallpaper
XWALLPAPER_VERSION := 0.6.6
DEB_XWALLPAPER_V   ?= $(XWALLPAPER_VERSION)

xwallpaper-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/stoeckmann/xwallpaper/releases/download/v0.6.6/xwallpaper-0.6.6.tar.xz{,.sig}
	$(call PGP_VERIFY,xwallpaper-$(XWALLPAPER_VERSION).tar.xz)
	$(call EXTRACT_TAR,xwallpaper-$(XWALLPAPER_VERSION).tar.xz,xwallpaper-$(XWALLPAPER_VERSION),xwallpaper)

ifneq ($(wildcard $(BUILD_WORK)/xwallpaper/.build_complete),)
xwallpaper:
	@echo "Using previously built xwallpaper."
else
xwallpaper: xwallpaper-setup libx11 libxau libxmu xorgproto libice
	cd $(BUILD_WORK)/xwallpaper && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-seccomp
	+$(MAKE) -C $(BUILD_WORK)/xwallpaper
	+$(MAKE) -C $(BUILD_WORK)/xwallpaper install \
		DESTDIR=$(BUILD_STAGE)/xwallpaper
	touch $(BUILD_WORK)/xwallpaper/.build_complete
endif

xwallpaper-package: xwallpaper-stage
	# xwallpaper.mk Package Structure
	rm -rf $(BUILD_DIST)/xwallpaper

	# xwallpaper.mk Prep xwallpaper
	cp -a $(BUILD_STAGE)/xwallpaper $(BUILD_DIST)

	# xwallpaper.mk Sign
	$(call SIGN,xwallpaper,general.xml)

	# xwallpaper.mk Make .debs
	$(call PACK,xwallpaper,DEB_XWALLPAPER_V)

	# xwallpaper.mk Build cleanup
	rm -rf $(BUILD_DIST)/xwallpaper

.PHONY: xwallpaper xwallpaper-package
