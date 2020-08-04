ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += libimobiledevice
LIBIMOBILEDEVICE_VERSION := 1.3.0
DEB_LIBIMOBILEDEVICE_V   ?= $(LIBIMOBILEDEVICE_VERSION)

libimobiledevice-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/libimobiledevice/releases/download/$(LIBIMOBILEDEVICE_VERSION)/libimobiledevice-$(LIBIMOBILEDEVICE_VERSION).tar.bz2
	$(call EXTRACT_TAR,libimobiledevice-$(LIBIMOBILEDEVICE_VERSION).tar.bz2,libimobiledevice-$(LIBIMOBILEDEVICE_VERSION),libimobiledevice)

ifneq ($(wildcard $(BUILD_WORK)/libimobiledevice/.build_complete),)
libimobiledevice:
	@echo "Using previously built libimobiledevice."
else
libimobiledevice: libimobiledevice-setup libusbmuxd libplist openssl
	cd $(BUILD_WORK)/libimobiledevice && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice install \
		DESTDIR="$(BUILD_STAGE)/libimobiledevice"
	+$(MAKE) -C $(BUILD_WORK)/libimobiledevice install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libimobiledevice/.build_complete
endif

libimobiledevice-package: libimobiledevice-stage
	# libimobiledevice.mk Package Structure
	rm -rf $(BUILD_DIST)/libimobiledevice{6,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libimobiledevice6/usr/lib \
		$(BUILD_DIST)/libimobiledevice-dev/usr/lib \
		$(BUILD_DIST)/libimobiledevice-utils/usr

	# libimobiledevice.mk Prep libimobiledevice6
	cp -a $(BUILD_STAGE)/libimobiledevice/usr/lib/libimobiledevice-1.0.6.dylib $(BUILD_DIST)/libimobiledevice6/usr/lib

	# libimobiledevice.mk Prep libimobiledevice-dev
	cp -a $(BUILD_STAGE)/libimobiledevice/usr/lib/{pkgconfig,libimobiledevice-1.0.{a,dylib}} $(BUILD_DIST)/libimobiledevice-dev/usr/lib
	cp -a $(BUILD_STAGE)/libimobiledevice/usr/include $(BUILD_DIST)/libimobiledevice-dev/usr

	# libimobiledevice.mk Prep libimobiledevice-utils
	cp -a $(BUILD_STAGE)/libimobiledevice/usr/{bin,share} $(BUILD_DIST)/libimobiledevice-utils/usr

	# libimobiledevice.mk Sign
	$(call SIGN,libimobiledevice6,general.xml)
	$(call SIGN,libimobiledevice-utils,general.xml)

	# libimobiledevice.mk Make .debs
	$(call PACK,libimobiledevice6,DEB_LIBIMOBILEDEVICE_V)
	$(call PACK,libimobiledevice-dev,DEB_LIBIMOBILEDEVICE_V)
	$(call PACK,libimobiledevice-utils,DEB_LIBIMOBILEDEVICE_V)

	# libimobiledevice.mk Build cleanup
	rm -rf $(BUILD_DIST)/libimobiledevice{6,-dev,-utils}

.PHONY: libimobiledevice libimobiledevice-package
