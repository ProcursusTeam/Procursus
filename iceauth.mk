ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += iceauth
ICEAUTH_VERSION := 1.0.8
DEB_ICEAUTH_V   ?= $(ICEAUTH_VERSION)

iceauth-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/app/iceauth-$(ICEAUTH_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,iceauth-$(ICEAUTH_VERSION).tar.gz)
	$(call EXTRACT_TAR,iceauth-$(ICEAUTH_VERSION).tar.gz,iceauth-$(ICEAUTH_VERSION),iceauth)

ifneq ($(wildcard $(BUILD_WORK)/iceauth/.build_complete),)
iceauth:
	@echo "Using previously built iceauth."
else
iceauth: iceauth-setup libx11 libxau libxmu xorgproto libice
	cd $(BUILD_WORK)/iceauth && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/iceauth
	+$(MAKE) -C $(BUILD_WORK)/iceauth install \
		DESTDIR=$(BUILD_STAGE)/iceauth
	touch $(BUILD_WORK)/iceauth/.build_complete
endif

iceauth-package: iceauth-stage
	# iceauth.mk Package Structure
	rm -rf $(BUILD_DIST)/iceauth

	# iceauth.mk Prep iceauth
	cp -a $(BUILD_STAGE)/iceauth $(BUILD_DIST)

	# iceauth.mk Sign
	$(call SIGN,iceauth,general.xml)

	# iceauth.mk Make .debs
	$(call PACK,iceauth,DEB_ICEAUTH_V)

	# iceauth.mk Build cleanup
	rm -rf $(BUILD_DIST)/iceauth

.PHONY: iceauth iceauth-package
