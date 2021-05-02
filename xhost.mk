ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xhost
XHOST_VERSION := 1.0.8
DEB_XHOST_V   ?= $(XHOST_VERSION)

xhost-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive//individual/app/xhost-$(XHOST_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xhost-$(XHOST_VERSION).tar.gz)
	$(call EXTRACT_TAR,xhost-$(XHOST_VERSION).tar.gz,xhost-$(XHOST_VERSION),xhost)

ifneq ($(wildcard $(BUILD_WORK)/xhost/.build_complete),)
xhost:
	@echo "Using previously built xhost."
else
xhost: xhost-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/xhost && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xhost
	+$(MAKE) -C $(BUILD_WORK)/xhost install \
		DESTDIR=$(BUILD_STAGE)/xhost
	+$(MAKE) -C $(BUILD_WORK)/xhost install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xhost/.build_complete
endif

xhost-package: xhost-stage
	# xhost.mk Package Structure
	rm -rf $(BUILD_DIST)/xhost

	# xhost.mk Prep xhost
	cp -a $(BUILD_STAGE)/xhost $(BUILD_DIST)

	# xhost.mk Sign
	$(call SIGN,xhost,general.xml)

	# xhost.mk Make .debs
	$(call PACK,xhost,DEB_XHOST_V)

	# xhost.mk Build cleanup
	rm -rf $(BUILD_DIST)/xhost

.PHONY: xhost xhost-package
