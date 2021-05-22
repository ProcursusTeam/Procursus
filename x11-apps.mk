ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += x11-apps
X11_APPS_VERSION := 7.7+8
DEB_X11_APPS_V   ?= $(X11_APPS_VERSION)

x11-apps-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://salsa.debian.org/xorg-team/app/x11-apps/-/archive/x11-apps-$(X11_APPS_VERSION)/x11-apps-x11-apps-$(X11_APPS_VERSION).tar.gz
	$(call EXTRACT_TAR,x11-apps-x11-apps-$(X11_APPS_VERSION).tar.gz,x11-apps-x11-apps-$(X11_APPS_VERSION),x11-apps)
	$(call DO_PATCH,xedit,x11-apps/xedit,-p1)

ifneq ($(wildcard $(BUILD_WORK)/x11-apps/.build_complete),)
x11-apps:
	@echo "Using previously built x11-apps."
else
x11-apps: x11-apps-setup libsm libx11 libxaw libxcursor libxext libxft libxmu libxrender libxt libpng16 libxkbfile
	+for dir in $(BUILD_WORK)/x11-apps/*; do \
		if [ -f $$dir/configure ]; then \
			cd $$dir && ./configure -C \
				$(DEFAULT_CONFIGURE_FLAGS) \
				--with-appdefaultdir=$(MEMO_PREFIX)/etc/X11/app-defaults; \
			$(MAKE) -C $$dir; \
			$(MAKE) -C $$dir install \
				DESTDIR=$(BUILD_STAGE)/x11-apps; \
		fi; \
	done
	touch $(BUILD_WORK)/x11-apps/.build_complete
endif

x11-apps-package: x11-apps-stage
	# x11-apps.mk Package Structure
	rm -rf $(BUILD_DIST)/x11-apps
	
	# x11-apps.mk Prep x11-apps
	cp -a $(BUILD_STAGE)/x11-apps $(BUILD_DIST)
	
	# x11-apps.mk Sign
	$(call SIGN,x11-apps,general.xml)
	
	# x11-apps.mk Make .debs
	$(call PACK,x11-apps,DEB_X11_APPS_V)
	
	# x11-apps.mk Build cleanup
	rm -rf $(BUILD_DIST)/x11-apps

.PHONY: x11-apps x11-apps-package
