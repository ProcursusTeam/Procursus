ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxext
LIBXEXT_VERSION := 1.3.4
DEB_LIBXEXT_V   ?= $(LIBXEXT_VERSION)-1

libxext-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXext-$(LIBXEXT_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXext-$(LIBXEXT_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXext-$(LIBXEXT_VERSION).tar.gz,libXext-$(LIBXEXT_VERSION),libxext)

ifneq ($(wildcard $(BUILD_WORK)/libxext/.build_complete),)
libxext:
	@echo "Using previously built libxext."
else
libxext: libxext-setup libx11 xorgproto
	cd $(BUILD_WORK)/libxext && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-silent-rules \
		--disable-dependency-tracking \
		--enable-malloc0returnsnull=no \
		--enable-specs=no
	+$(MAKE) -C $(BUILD_WORK)/libxext
	+$(MAKE) -C $(BUILD_WORK)/libxext install \
		DESTDIR=$(BUILD_STAGE)/libxext
	+$(MAKE) -C $(BUILD_WORK)/libxext install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxext/.build_complete
endif

libxext-package: libxext-stage
	# libxext.mk Package Structure
	rm -rf $(BUILD_DIST)/libxext{6,-dev,-doc}
	mkdir -p $(BUILD_DIST)/libxext{6,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxext-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxext.mk Prep libxext6
	cp -a $(BUILD_STAGE)/libxext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXext.6.dylib $(BUILD_DIST)/libxext6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxext.mk Prep libxext-dev
	cp -a $(BUILD_STAGE)/libxext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXext.{a,dylib},pkgconfig} $(BUILD_DIST)/libxext-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxext-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxext.mk Prep libxext-doc
	cp -a $(BUILD_STAGE)/libxext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libxext-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxext.mk Sign
	$(call SIGN,libxext6,general.xml)

	# libxext.mk Make .debs
	$(call PACK,libxext6,DEB_LIBXEXT_V)
	$(call PACK,libxext-dev,DEB_LIBXEXT_V)
	$(call PACK,libxext-doc,DEB_LIBXEXT_V)

	# libxext.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxext{6,-dev,-doc}

.PHONY: libxext libxext-package
