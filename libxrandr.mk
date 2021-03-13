ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libxrandr
LIBXRANDR_VERSION := 1.5.2
DEB_LIBXRANDR_V   ?= $(LIBXRANDR_VERSION)

libxrandr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXrandr-$(LIBXRANDR_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXrandr-$(LIBXRANDR_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXrandr-$(LIBXRANDR_VERSION).tar.gz,libXrandr-$(LIBXRANDR_VERSION),libxrandr)

ifneq ($(wildcard $(BUILD_WORK)/libxrandr/.build_complete),)
libxrandr:
	@echo "Using previously built libxrandr."
else
libxrandr: libxrandr-setup libx11 libxrender libxext xorgproto
	cd $(BUILD_WORK)/libxrandr && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxrandr
	+$(MAKE) -C $(BUILD_WORK)/libxrandr install \
		DESTDIR=$(BUILD_STAGE)/libxrandr
	+$(MAKE) -C $(BUILD_WORK)/libxrandr install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxrandr/.build_complete
endif

libxrandr-package: libxrandr-stage
	# libxrandr.mk Package Structure
	rm -rf $(BUILD_DIST)/libxrandr{2,-dev}
	mkdir -p $(BUILD_DIST)/libxrandr{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# libxrandr.mk Prep libxrandr2
	cp -a $(BUILD_STAGE)/libxrandr/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libXrandr.2.dylib $(BUILD_DIST)/libxrandr2/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# libxrandr.mk Prep libxrandr-dev
	cp -a $(BUILD_STAGE)/libxrandr/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libXrandr{.a,.dylib} $(BUILD_DIST)/libxrandr-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	cp -a $(BUILD_STAGE)/libxrandr/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/pkgconfig $(BUILD_DIST)/libxrandr-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libxrandr/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{include,share} $(BUILD_DIST)/libxrandr-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	
	# libxrandr.mk Sign
	$(call SIGN,libxrandr2,general.xml)
	
	# libxrandr.mk Make .debs
	$(call PACK,libxrandr2,DEB_LIBXRANDR_V)
	$(call PACK,libxrandr-dev,DEB_LIBXRANDR_V)
	
	# libxrandr.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxrandr{2,-dev}

.PHONY: libxrandr libxrandr-package
