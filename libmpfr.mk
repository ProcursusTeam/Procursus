ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libmpfr
LIBMPFR_VERSION := 4.1.0
DEB_LIBMPFR_V   ?= $(LIBMPFR_VERSION)

libmpfr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.mpfr.org/mpfr-current/mpfr-$(LIBMPFR_VERSION).tar.gz
	$(call EXTRACT_TAR,mpfr-$(LIBMPFR_VERSION).tar.gz,mpfr-$(LIBMPFR_VERSION),libmpfr)

ifneq ($(wildcard $(BUILD_WORK)/libmpfr/.build_complete),)
libmpfr:
	@echo "Using previously built libmpfr."
else
libmpfr: libmpfr-setup
	cd $(BUILD_WORK)/libmpfr && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/linmpfr
	+$(MAKE) -C $(BUILD_WORK)/libmpfr install \
		DESTDIR=$(BUILD_STAGE)/mpfr
	+$(MAKE) -C $(BUILD_WORK)/libmpfr install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libmpfr/.build_complete
endif

libmpfr-package: libmpfr-stage
	# libmpfr.mk Package Structure
	rm -rf $(BUILD_DIST)/{libmpfr6,libmpfr-dev}
	mkdir -p \
        	$(BUILD_DIST)/libmpfr6/usr/lib
        	$(BUILD_DIST)/libmpfr-dev/usr/{lib,include}
	
	# libmpfr.mk Prep mpfr
	cp -a $(BUILD_STAGE)/libmpfr/usr/lib/libmpfr*dylib $(BUILD_DIST)/libmpfr6/usr/lib
	cp -a $(BUILD_STAGE)/libmpfr/usr/include $(BUILD_DIST)/libmpfr-dev/usr
	cp -a $(BUILD_STAGE)/libmpfr/usr/lib/libmpfr.a $(BUILD_DIST)/libmpfr-dev/usr/lib
	
	# libmpfr.mk Sign
	$(call SIGN,libmpfr6,general.xml)
	$(call SIGN,libmpfr-dev,general.xml)
	
	# libmpfr.mk Make .debs
	$(call PACK,libmpfr6,DEB_LIBMPFR_V)
	$(call PACK,libmpfr-dev,DEB_LIBMPFR_V)
	
	# libmpfr.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libmpfr6,libmpfr-dev}

.PHONY: libmpfr libmpfr-package
