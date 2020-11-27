ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libtiff
LIBTIFF_VERSION := 4.1.0
DEB_LIBTIFF_V   ?= $(LIBTIFF_VERSION)

libtiff-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://download.osgeo.org/libtiff/tiff-$(LIBTIFF_VERSION).tar.gz
	$(call EXTRACT_TAR,tiff-$(LIBTIFF_VERSION).tar.gz,tiff-$(LIBTIFF_VERSION),libtiff)
	$(call DO_PATCH,libtiff,libtiff,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libtiff/.build_complete),)
libtiff:
	@echo "Using previously built libtiff."
else
libtiff: libtiff-setup libjpeg-turbo xz zstd
	cd $(BUILD_WORK)/libtiff && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-webp
	+$(MAKE) -C $(BUILD_WORK)/libtiff
	+$(MAKE) -C $(BUILD_WORK)/libtiff install \
		DESTDIR="$(BUILD_STAGE)/libtiff"
	+$(MAKE) -C $(BUILD_WORK)/libtiff install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtiff/.build_complete
endif

libtiff-package: libtiff-stage
  # libtiff.mk Package Structure
	rm -rf $(BUILD_DIST)/libtiff{-dev,-doc-tools,5,xx5}
	mkdir -p \
		$(BUILD_DIST)/libtiff-dev/usr/{lib,share/man} \
		$(BUILD_DIST)/libtiff-doc/usr/share \
		$(BUILD_DIST)/libtiff-tools/usr/share/man \
		$(BUILD_DIST)/libtiff{5,xx5}/usr/lib

  # libtiff.mk Prep libtiff-dev
	cp -a $(BUILD_STAGE)/libtiff/usr/include $(BUILD_DIST)/libtiff-dev/usr
	cp -a $(BUILD_STAGE)/libtiff/usr/lib/libtiff{,xx}.{a,la,dylib} $(BUILD_DIST)/libtiff-dev/usr/lib
	cp -a $(BUILD_STAGE)/libtiff/usr/lib/pkgconfig $(BUILD_DIST)/libtiff-dev/usr/lib
	cp -a $(BUILD_STAGE)/libtiff/usr/share/man/man3 $(BUILD_DIST)/libtiff-dev/usr/share/man

  # libtiff.mk Prep libtiff-doc
	cp -a $(BUILD_STAGE)/libtiff/usr/share/doc $(BUILD_DIST)/libtiff-doc/usr/share

  # libtiff.mk Prep libtiff-tools
	cp -a $(BUILD_STAGE)/libtiff/usr/bin $(BUILD_DIST)/libtiff-tools/usr
	cp -a $(BUILD_STAGE)/libtiff/usr/share/man/man1 $(BUILD_DIST)/libtiff-tools/usr/share/man

  # libtiff.mk Prep libtiff5
	cp -a $(BUILD_STAGE)/libtiff/usr/lib/libtiff.*.dylib $(BUILD_DIST)/libtiff5/usr/lib

  # libtiff.mk Prep libtiffxx5
	cp -a $(BUILD_STAGE)/libtiff/usr/lib/libtiffxx.*.dylib $(BUILD_DIST)/libtiff5/usr/lib


  # libtiff.mk Sign
	$(call SIGN,libtiff-dev,general.xml)
	$(call SIGN,libtiff-tools,general.xml)
	$(call SIGN,libtiff5,general.xml)
	$(call SIGN,libtiffxx5,general.xml)

  # libtiff.mk Make .debs
	$(call PACK,libtiff-dev,DEB_LIBTIFF_V)
	$(call PACK,libtiff-doc,DEB_LIBTIFF_V)
	$(call PACK,libtiff-tools,DEB_LIBTIFF_V)
	$(call PACK,libtiff5,DEB_LIBTIFF_V)
	$(call PACK,libtiffxx5,DEB_LIBTIFF_V)

  # libtiff.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtiff{-dev,-doc,-tools,5,xx5}

.PHONY: libtiff libtiff-package
