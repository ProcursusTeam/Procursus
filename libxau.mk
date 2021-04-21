ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxau
LIBXAU_VERSION := 1.0.9
DEB_LIBXAU_V   ?= $(LIBXAU_VERSION)-1

libxau-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXau-$(LIBXAU_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXau-$(LIBXAU_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXau-$(LIBXAU_VERSION).tar.gz,libXau-$(LIBXAU_VERSION),libxau)

ifneq ($(wildcard $(BUILD_WORK)/libxau/.build_complete),)
libxau:
	@echo "Using previously built libxau."
else
libxau: libxau-setup xorgproto
	cd $(BUILD_WORK)/libxau && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxau
	+$(MAKE) -C $(BUILD_WORK)/libxau install \
		DESTDIR=$(BUILD_STAGE)/libxau
	+$(MAKE) -C $(BUILD_WORK)/libxau install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxau/.build_complete
endif

libxau-package: libxau-stage
	# libxau.mk Package Structure
	rm -rf $(BUILD_DIST)/libxau{6,-dev}
	mkdir -p $(BUILD_DIST)/libxau6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxau-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libxau.mk Prep libxau6
	cp -a $(BUILD_STAGE)/libxau/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXau.6.dylib $(BUILD_DIST)/libxau6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxau.mk Prep libxau-dev
	cp -a $(BUILD_STAGE)/libxau/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXau{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxau-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxau/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxau-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxau.mk Sign
	$(call SIGN,libxau6,general.xml)

	# libxau.mk Make .debs
	$(call PACK,libxau6,DEB_LIBXAU_V)
	$(call PACK,libxau-dev,DEB_LIBXAU_V)

	# libxau.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxau{6,-dev}

.PHONY: libxau libxau-package
