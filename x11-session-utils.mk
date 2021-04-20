ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += x11-session-utils
x11-SESSION-UTILS_VERSION := 7.7
DEB_x11-SESSION-UTILS_V   ?= $(X11-SESSION-UTILS_VERSION)

x11-session-utils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/x/x11-session-utils/x11-session-utils_$(X11-SESSION-UTILS_VERSION)+3.tar.gz
	$(call EXTRACT_TAR,x11-session-utils_$(X11-SESSION-UTILS_VERSION)+3.tar.gz,x11-session-utils-$(X11-SESSION-UTILS_VERSION),x11-session-utils)

ifneq ($(wildcard $(BUILD_WORK)/x11-session-utils/.build_complete),)
x11-session-utils:
	@echo "Using previously built x11-session-utils."
else
x11-session-utils: x11-session-utils-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/x11-session-utils/xsm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/xsm
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/xsm install \
		DESTDIR=$(BUILD_STAGE)/x11-session-utils
	cd $(BUILD_WORK)/x11-session-utils/smproxy && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/smproxy
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/smproxy install \
		DESTDIR=$(BUILD_STAGE)/x11-session-utils
	cd $(BUILD_WORK)/x11-session-utils/rstart && autoreconf -fiv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/rstart
	+$(MAKE) -C $(BUILD_WORK)/x11-session-utils/rstart install \
		DESTDIR=$(BUILD_STAGE)/x11-session-utils
	touch $(BUILD_WORK)/x11-session-utils/.build_complete
endif

x11-session-utils-package: x11-session-utils-stage
	# x11-session-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/x11-session-utils

	# x11-session-utils.mk Prep x11-session-utils
	cp -a $(BUILD_STAGE)/x11-session-utils $(BUILD_DIST)

	# x11-session-utils.mk Sign
	$(call SIGN,x11-session-utils,general.xml)

	# x11-session-utils.mk Make .debs
	$(call PACK,x11-session-utils,DEB_X11-SESSION-UTILS_V)

	# x11-session-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/x11-session-utils

.PHONY: x11-session-utils x11-session-utils-package
