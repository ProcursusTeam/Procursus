ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libtiff
LIBTIFF_VERSION := 4.2.0
DEB_LIBTIFF_V   ?= $(LIBTIFF_VERSION)

libtiff-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://download.osgeo.org/libtiff/tiff-$(LIBTIFF_VERSION).tar.gz
	$(call EXTRACT_TAR,tiff-$(LIBTIFF_VERSION).tar.gz,tiff-$(LIBTIFF_VERSION),libtiff)

ifneq ($(wildcard $(BUILD_WORK)/libtiff/.build_complete),)
libtiff:
	@echo "Using previously built libtiff."
else
libtiff: libtiff-setup libjpeg-turbo xz zstd
	cd $(BUILD_WORK)/libtiff && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
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
		$(BUILD_DIST)/libtiff-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man} \
		$(BUILD_DIST)/libtiff-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libtiff-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libtiff{5,xx5}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtiff.mk Prep libtiff-dev
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtiff-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtiff{,xx}.{a,la,dylib} $(BUILD_DIST)/libtiff-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libtiff-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libtiff-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libtiff.mk Prep libtiff-doc
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc $(BUILD_DIST)/libtiff-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libtiff.mk Prep libtiff-tools
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libtiff-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/libtiff-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libtiff.mk Prep libtiff5
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtiff.*.dylib $(BUILD_DIST)/libtiff5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtiff.mk Prep libtiffxx5
	cp -a $(BUILD_STAGE)/libtiff/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtiffxx.*.dylib $(BUILD_DIST)/libtiff5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib


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
