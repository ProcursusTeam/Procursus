ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libxxf86dga
LIBXXF86DGA_VERSION := 1.1.5
DEB_LIBXXF86DGA_V   ?= $(LIBXXF86DGA_VERSION)

libxxf86dga-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXxf86dga-$(LIBXXF86DGA_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXxf86dga-$(LIBXXF86DGA_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXxf86dga-$(LIBXXF86DGA_VERSION).tar.bz2,libXxf86dga-$(LIBXXF86DGA_VERSION),libxxf86dga)

ifneq ($(wildcard $(BUILD_WORK)/libxxf86dga/.build_complete),)
libxxf86dga:
	@echo "Using previously built libxxf86dga."
else
libxxf86dga: libxxf86dga-setup libx11 libxext util-macros xorgproto
	cd $(BUILD_WORK)/libxxf86dga && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		  --enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxxf86dga
	+$(MAKE) -C $(BUILD_WORK)/libxxf86dga install \
		DESTDIR=$(BUILD_STAGE)/libxxf86dga
	$(call AFTER_BUILD,copy)
endif

libxxf86dga-package: libxxf86dga-stage
	# libxxf86dga.mk Package Structure
	rm -rf $(BUILD_DIST)/libxxf86dga{1,-dev}
	mkdir -p $(BUILD_DIST)/libxxf86dga{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxxf86dga.mk Prep libxxf86dga1
	cp -a $(BUILD_STAGE)/libxxf86dga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXxf86dga.1.dylib $(BUILD_DIST)/libxxf86dga1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxxf86dga.mk Prep libxxf86dga-dev
	cp -a $(BUILD_STAGE)/libxxf86dga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxxf86dga-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxxf86dga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libXxf86dga.{dylib,a}} $(BUILD_DIST)/libxxf86dga-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxxf86dga.mk Sign
	$(call SIGN,libxxf86dga1,general.xml)

	# libxxf86dga.mk Make .debs
	$(call PACK,libxxf86dga1,DEB_LIBXXF86DGA_V)
	$(call PACK,libxxf86dga-dev,DEB_LIBXXF86DGA_V)

	# libxxf86dga.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxxf86dga{1,-dev}

.PHONY: libxxf86dga libxxf86dga-package
