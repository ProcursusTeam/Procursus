ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xsetroot
XSETROOT_VERSION := 1.1.2
DEB_XSETROOT_V   ?= $(XSETROOT_VERSION)

xsetroot-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/app/xsetroot-$(XSETROOT_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,xsetroot-$(XSETROOT_VERSION).tar.gz)
	$(call EXTRACT_TAR,xsetroot-$(XSETROOT_VERSION).tar.gz,xsetroot-$(XSETROOT_VERSION),xsetroot)

ifneq ($(wildcard $(BUILD_WORK)/xsetroot/.build_complete),)
xsetroot:
	@echo "Using previously built xsetroot."
else
xsetroot: xsetroot-setup libx11 libxau libxmu xorgproto libice
	cd $(BUILD_WORK)/xsetroot && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xsetroot
	+$(MAKE) -C $(BUILD_WORK)/xsetroot install \
		DESTDIR=$(BUILD_STAGE)/xsetroot
	touch $(BUILD_WORK)/xsetroot/.build_complete
endif

xsetroot-package: xsetroot-stage
	# xsetroot.mk Package Structure
	rm -rf $(BUILD_DIST)/xsetroot

	# xsetroot.mk Prep xsetroot
	cp -a $(BUILD_STAGE)/xsetroot $(BUILD_DIST)

	# xsetroot.mk Sign
	$(call SIGN,xsetroot,general.xml)

	# xsetroot.mk Make .debs
	$(call PACK,xsetroot,DEB_XSETROOT_V)

	# xsetroot.mk Build cleanup
	rm -rf $(BUILD_DIST)/xsetroot

.PHONY: xsetroot xsetroot-package
