ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libmpfr
LIBMPFR_VERSION := 4.1.0
DEB_LIBMPFR_V   ?= $(LIBMPFR_VERSION)

libmpfr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.mpfr.org/mpfr-current/mpfr-$(LIBMPFR_VERSION).tar.gz
	$(call EXTRACT_TAR,mpfr-$(LIBMPFR_VERSION).tar.gz,mpfr-$(LIBMPFR_VERSION),mpfr)

ifneq ($(wildcard $(BUILD_WORK)/mpfr/.build_complete),)
libmpfr:
	@echo "Using previously built libmpfr."
else
libmpfr:
	cd $(BUILD_WORK)/mpfr && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/mpfr
	+$(MAKE) -C $(BUILD_WORK)/mpfr install \
		DESTDIR=$(BUILD_STAGE)/mpfr
	+$(MAKE) -C $(BUILD_WORK)/mpfr install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/mpfr/.build_complete
endif

libmpfr-package: libmpfr-stage
	# libmpfr.mk Package Structure
	rm -rf $(BUILD_DIST)/libmpfr
	mkdir -p \
        	$(BUILD_DIST)/libmpfr6/usr
        	$(BUILD_DIST)/libmpfr-dev/usr/{lib,include}
	
	# libmpfr.mk Prep mpfr
	cp -a $(BUILD_STAGE)/mpfr/usr/lib/libmpfr*dylib $(BUILD_DIST)/libmpfr6/usr/lib
    	cp -a $(BUILD_STAGE)/mpfr/usr/include $(BUILD_DIST)/libmpfr-dev/usr
    	cp -a $(BUILD_STAGE)/mpfr/usr/lib/libmpfr.a $(BUILD_DIST)/libmpfr-dev/usr/lib
	
	# libmpfr.mk Sign
	$(call SIGN,libmpfr6,general.xml)
    	$(call SIGN,libmpfr-dev,general.xml)
	
	# libmpfr.mk Make .debs
	$(call PACK,libmpfr6,DEB_LIBMPfr_V)
    	$(call PACK,libmpfr-dev,DEB_LIBMPfr_V)
	
	# libmpfr.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmpfr

.PHONY: libmpfr libmpfr-package
