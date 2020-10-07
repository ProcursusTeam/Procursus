ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += libffi
LIBFFI_VERSION := 3.3
DEB_LIBFFI_V   ?= $(LIBFFI_VERSION)-1

libffi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sourceware.org/pub/libffi/libffi-$(LIBFFI_VERSION).tar.gz
	$(call EXTRACT_TAR,libffi-$(LIBFFI_VERSION).tar.gz,libffi-$(LIBFFI_VERSION),libffi)

ifneq ($(wildcard $(BUILD_WORK)/libffi/.build_complete),)
libffi:
	@echo "Using previously built libffi."
else
libffi: libffi-setup
	cd $(BUILD_WORK)/libffi && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libffi
	+$(MAKE) -C $(BUILD_WORK)/libffi install \
		DESTDIR=$(BUILD_STAGE)/libffi
	+$(MAKE) -C $(BUILD_WORK)/libffi install \
                DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libffi/.build_complete
endif

libffi-package: libffi-stage
	# libffi.mk Package Structure
	rm -rf $(BUILD_DIST)/libffi{7,-dev}
	mkdir -p $(BUILD_DIST)/libffi{7,-dev}/usr/lib
	
	# libffi.mk Prep libffi7
	cp -a $(BUILD_STAGE)/libffi/usr/lib/libffi.7.dylib $(BUILD_DIST)/libffi7/usr/lib

	# libffi.mk Prep libffi-dev
	cp -a $(BUILD_STAGE)/libffi/usr/lib/!(libffi.7.dylib) $(BUILD_DIST)/libffi-dev/usr/lib
	cp -a $(BUILD_STAGE)/libffi/usr/{include,share} $(BUILD_DIST)/libffi-dev/usr
	
	# libffi.mk Sign
	$(call SIGN,libffi7,general.xml)
	
	# libffi.mk Make .debs
	$(call PACK,libffi7,DEB_LIBFFI_V)
	$(call PACK,libffi-dev,DEB_LIBFFI_V)
	
	# libffi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libffi{7,-dev}

.PHONY: libffi libffi-package
