ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libirecovery
LIBIRECOVERY_VERSION := 1.0.0
DEB_LIBIRECOVERY_V   ?= $(LIBIRECOVERY_VERSION)-1

libirecovery-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/libirecovery/releases/download/$(LIBIRECOVERY_VERSION)/libirecovery-$(LIBIRECOVERY_VERSION).tar.bz2
	$(call EXTRACT_TAR,libirecovery-$(LIBIRECOVERY_VERSION).tar.bz2,libirecovery-$(LIBIRECOVERY_VERSION),libirecovery)

ifneq ($(wildcard $(BUILD_WORK)/libirecovery/.build_complete),)
libirecovery:
	@echo "Using previously built libirecovery."
else
libirecovery: libirecovery-setup readline libusb
	cd $(BUILD_WORK)/libirecovery && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libirecovery \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/usr/include/libusb-1.0"
	+$(MAKE) -C $(BUILD_WORK)/libirecovery install \
		DESTDIR=$(BUILD_STAGE)/libirecovery
	+$(MAKE) -C $(BUILD_WORK)/libirecovery install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libirecovery/.build_complete
endif

libirecovery-package: libirecovery-stage
	# libirecovery.mk Package Structure
	rm -rf $(BUILD_DIST)/libirecovery
	mkdir -p $(BUILD_DIST)/libirecovery
	
	# libirecovery.mk Prep libirecovery
	cp -a $(BUILD_STAGE)/libirecovery/usr $(BUILD_DIST)/libirecovery
	
	# libirecovery.mk Sign
	$(call SIGN,libirecovery,general.xml)
	
	# libirecovery.mk Make .debs
	$(call PACK,libirecovery,DEB_LIBIRECOVERY_V)
	
	# libirecovery.mk Build cleanup
	rm -rf $(BUILD_DIST)/libirecovery

.PHONY: libirecovery libirecovery-package
