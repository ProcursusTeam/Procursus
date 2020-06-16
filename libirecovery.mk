ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libirecovery
DOWNLOAD             += https://github.com/libimobiledevice/libirecovery/archive/$(LIBIRECOVERY_VERSION).tar.gz
LIBIRECOVERY_VERSION := 1.0.0
DEB_LIBIRECOVERY_V   ?= $(LIBIRECOVERY_VERSION)

libirecovery-setup: setup
	$(call EXTRACT_TAR,libirecovery-$(LIBIRECOVERY_VERSION).tar.gz,libirecovery-$(LIBIRECOVERY_VERSION),libirecovery)

ifneq ($(wildcard $(BUILD_WORK)/libirecovery/.build_complete),)
libirecovery:
	@echo "Using previously built libirecovery."
else
libirecovery: libirecovery-setup readline
	cd $(BUILD_WORK)/libirecovery && ./autogen.sh -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-sysroot=$(SYSROOT) \
		--with-iokit 
	+$(MAKE) -C $(BUILD_WORK)/libirecovery
	+$(MAKE) -C $(BUILD_WORK)/libirecovery install \
		DESTDIR=$(BUILD_STAGE)/libirecovery
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
