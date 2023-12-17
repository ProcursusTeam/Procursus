ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += x11-xserver-utils
X11-XSERVER-UTILS-VERSION := 7.7+8
DEB_X11-XSERVER-UTILS_V   ?= $(X11-XSERVER-UTILS-VERSION)

x11-xserver-utils-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://salsa.debian.org/xorg-team/app/x11-xserver-utils/-/archive/x11-xserver-utils-$(X11-XSERVER-UTILS-VERSION)/x11-xserver-utils-x11-xserver-utils-$(X11-XSERVER-UTILS-VERSION).tar.gz
	$(call EXTRACT_TAR,x11-xserver-utils-x11-xserver-utils-$(X11-XSERVER-UTILS-VERSION).tar.gz,x11-xserver-utils-x11-xserver-utils-$(X11-XSERVER-UTILS-VERSION),x11-xserver-utils)

ifneq ($(wildcard $(BUILD_WORK)/x11-xserver-utils/.build_complete),)
x11-xserver-utils:
	@echo "Using previously built x11-xserver-utils."
else
x11-xserver-utils: x11-xserver-utils-setup libsm libx11 libxaw libxcursor libxext libxft libxmu libxrender libxt libpng16 libxkbfile xbitmaps
	+for dir in $(BUILD_WORK)/x11-xserver-utils/*; do \
		if [ -f $$dir/configure ]; then \
			cd $$dir && autoreconf -fiv && ./configure -C \
				$(DEFAULT_CONFIGURE_FLAGS) \
				PKG_CONFIG="pkg-config --define-prefix"; \
			$(MAKE) -C $$dir; \
			$(MAKE) -C $$dir install \
				DESTDIR=$(BUILD_STAGE)/x11-xserver-utils; \
		fi; \
	done
	touch $(BUILD_WORK)/x11-xserver-utils/.build_complete
endif

x11-xserver-utils-package: x11-xserver-utils-stage
	# x11-xserver-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/x11-xserver-utils
	
	# x11-xserver-utils.mk Prep x11-xserver-utils
	cp -a $(BUILD_STAGE)/x11-xserver-utils $(BUILD_DIST)
	
	# x11-xserver-utils.mk Sign
	$(call SIGN,x11-xserver-utils,general.xml)
	
	# x11-xserver-utils.mk Make .debs
	$(call PACK,x11-xserver-utils,DEB_X11-XSERVER-UTILS_V)
	
	# x11-xserver-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/x11-xserver-utils

.PHONY: x11-xserver-utils x11-xserver-utils-package
