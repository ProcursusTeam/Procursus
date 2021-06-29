ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                += hicolor-icon-theme
HICOLOR-ICON-THEME_VERSION := 0.17
DEB_HICOLOR-ICON-THEME_V   ?= $(HICOLOR-ICON-THEME_VERSION)

hicolor-icon-theme-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-$(HICOLOR-ICON-THEME_VERSION).tar.xz
	$(call EXTRACT_TAR,hicolor-icon-theme-$(HICOLOR-ICON-THEME_VERSION).tar.xz,hicolor-icon-theme-$(HICOLOR-ICON-THEME_VERSION),hicolor-icon-theme)

ifneq ($(wildcard $(BUILD_WORK)/hicolor-icon-theme/.build_complete),)
hicolor-icon-theme:
	@echo "Using previously built hicolor-icon-theme."
else
hicolor-icon-theme: hicolor-icon-theme-setup
	cd $(BUILD_WORK)/hicolor-icon-theme && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/hicolor-icon-theme install \
		DESTDIR=$(BUILD_STAGE)/hicolor-icon-theme
	touch $(BUILD_WORK)/hicolor-icon-theme/.build_complete
endif

hicolor-icon-theme-package: hicolor-icon-theme-stage
	# hicolor-icon-theme.mk Package Structure
	rm -rf $(BUILD_DIST)/hicolor-icon-theme

	# hicolor-icon-theme.mk Prep hicolor-icon-theme
	cp -a $(BUILD_STAGE)/hicolor-icon-theme $(BUILD_DIST)

	# hicolor-icon-theme.mk Make .debs
	$(call PACK,hicolor-icon-theme,DEB_HICOLOR-ICON-THEME_V)

	# hicolor-icon-theme.mk Build cleanup
	rm -rf $(BUILD_DIST)/hicolor-icon-theme

.PHONY: hicolor-icon-theme hicolor-icon-theme-package
