ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xauth
XAUTH_VERSION := 1.1
DEB_XAUTH_V   ?= $(XAUTH_VERSION)

xauth-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/app/xauth-$(XAUTH_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xauth-$(XAUTH_VERSION).tar.gz)
	$(call EXTRACT_TAR,xauth-$(XAUTH_VERSION).tar.gz,xauth-$(XAUTH_VERSION),xauth)

ifneq ($(wildcard $(BUILD_WORK)/xauth/.build_complete),)
xauth:
	@echo "Using previously built xauth."
else
xauth: xauth-setup libx11 libxau libxext libxmu xorgproto
	cd $(BUILD_WORK)/xauth && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xauth
	+$(MAKE) -C $(BUILD_WORK)/xauth install \
		DESTDIR=$(BUILD_STAGE)/xauth
	+$(MAKE) -C $(BUILD_WORK)/xauth install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xauth/.build_complete
endif

xauth-package: xauth-stage
	# xauth.mk Package Structure
	rm -rf $(BUILD_DIST)/xauth

	# xauth.mk Prep xauth
	cp -a $(BUILD_STAGE)/xauth $(BUILD_DIST)

	# xauth.mk Sign
	$(call SIGN,xauth,general.xml)

	# xauth.mk Make .debs
	$(call PACK,xauth,DEB_XAUTH_V)

	# xauth.mk Build cleanup
	rm -rf $(BUILD_DIST)/xauth

.PHONY: xauth xauth-package
