ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += xfe
XFE_VERSION := 1.44
DEB_XFE_V   ?= $(XFE_VERSION)

xfe-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://pilotfiber.dl.sourceforge.net/project/xfe/xfe/1.44/xfe-1.44.tar.xz
	$(call EXTRACT_TAR,xfe-$(XFE_VERSION).tar.xz,xfe-$(XFE_VERSION),xfe)

ifneq ($(wildcard $(BUILD_WORK)/xfe/.build_complete),)
xfe:
	@echo "Using previously built xfe."
else
xfe: xfe-setup fox1.6 gettext fontconfig freetype libpng16 libxft libxrandr libx11
	cd $(BUILD_WORK)/xfe && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-release \
		--with-x \
		--disable-sn \
		--with-xrandr \
		ac_cv_func_malloc_0_nonnull=yes \
		FOX_CONFIG="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fox-config"
	+$(MAKE) -C $(BUILD_WORK)/xfe \
		CXXFLAGS+=\ -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/fox-1.6
	+$(MAKE) -C $(BUILD_WORK)/xfe install \
		DESTDIR=$(BUILD_STAGE)/xfe
	touch $(BUILD_WORK)/xfe/.build_complete
endif

xfe-package: xfe-stage
# xfe.mk Package Structure
	rm -rf $(BUILD_DIST)/xfe
	
# xfe.mk Prep xfe
	cp -a $(BUILD_STAGE)/xfe $(BUILD_DIST)
	
# xfe.mk Sign
	$(call SIGN,xfe,general.xml)
	
# xfe.mk Make .debs
	$(call PACK,xfe,DEB_XFE_V)
	
# xfe.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfe

.PHONY: xfe xfe-package
