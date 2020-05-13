ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libffi
DOWNLOAD        += https://sourceware.org/pub/libffi/libffi-$(LIBFFI_VERSION).tar.gz
LIBFFI_VERSION  := 3.3
DEB_LIBFFI_V    ?= $(LIBFFI_VERSION)

libffi-setup: setup
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
	rm -rf $(BUILD_DIST)/libffi
	mkdir -p $(BUILD_DIST)/libffi
	
	# libffi.mk Prep libffi
	cp -a $(BUILD_STAGE)/libffi/usr $(BUILD_DIST)/libffi
	
	# libffi.mk Sign
	$(call SIGN,libffi,general.xml)
	
	# libffi.mk Make .debs
	$(call PACK,libffi,DEB_LIBFFI_V)
	
	# libffi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libffi

.PHONY: libffi libffi-package
