ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libxv
LIBXV_VERSION := 1.0.11
DEB_LIBXV_V   ?= $(LIBXV_VERSION)

libxv-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXv-$(LIBXV_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXv-$(LIBXV_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXv-$(LIBXV_VERSION).tar.bz2,libXv-$(LIBXV_VERSION),libxv)

ifneq ($(wildcard $(BUILD_WORK)/libxv/.build_complete),)
libxv:
	@echo "Using previously built libxv."
else
libxv: libxv-setup libx11 libxext xorgproto
	cd $(BUILD_WORK)/libxv && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		  --enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxv
	+$(MAKE) -C $(BUILD_WORK)/libxv install \
		DESTDIR=$(BUILD_STAGE)/libxv
	$(call AFTER_BUILD,copy)
endif

libxv-package: libxv-stage
	# libxv.mk Package Structure
	rm -rf $(BUILD_DIST)/libxv{1,-dev}
	mkdir -p $(BUILD_DIST)/libxv{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxv.mk Prep libxv1
	cp -a $(BUILD_STAGE)/libxv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXv.1.dylib $(BUILD_DIST)/libxv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxv.mk Prep libxv-dev
	cp -a $(BUILD_STAGE)/libxv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libXv.{dylib,a}} $(BUILD_DIST)/libxv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxv.mk Sign
	$(call SIGN,libxv1,general.xml)

	# libxv.mk Make .debs
	$(call PACK,libxv1,DEB_LIBXV_V)
	$(call PACK,libxv-dev,DEB_LIBXV_V)

	# libxv.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxv{1,-dev}

.PHONY: libxv libxv-package
