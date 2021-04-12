ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libfontenc
LIBFONTENC_VERSION := 1.1.4
DEB_LIBFONTENC_V   ?= $(LIBFONTENC_VERSION)

libfontenc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libfontenc-$(LIBFONTENC_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libfontenc-$(LIBFONTENC_VERSION).tar.gz)
	$(call EXTRACT_TAR,libfontenc-$(LIBFONTENC_VERSION).tar.gz,libfontenc-$(LIBFONTENC_VERSION),libfontenc)

ifneq ($(wildcard $(BUILD_WORK)/libfontenc/.build_complete),)
libfontenc:
	@echo "Using previously built libfontenc."
else
libfontenc: libfontenc-setup
	cd $(BUILD_WORK)/libfontenc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libfontenc
	+$(MAKE) -C $(BUILD_WORK)/libfontenc install \
		DESTDIR=$(BUILD_STAGE)/libfontenc
	+$(MAKE) -C $(BUILD_WORK)/libfontenc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libfontenc/.build_complete
endif

libfontenc-package: libfontenc-stage
	# libfontenc.mk Package Structure
	rm -rf $(BUILD_DIST)/libfontenc{1,-dev}
	mkdir -p $(BUILD_DIST)/libfontenc{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfontenc.mk Prep libfontenc6
	cp -a $(BUILD_STAGE)/libfontenc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfontenc.1.dylib $(BUILD_DIST)/libfontenc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfontenc.mk Prep libfontenc-dev
	cp -a $(BUILD_STAGE)/libfontenc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libfontenc.{a,dylib},pkgconfig} $(BUILD_DIST)/libfontenc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfontenc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfontenc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libfontenc.mk Sign
	$(call SIGN,libfontenc1,general.xml)

	# libfontenc.mk Make .debs
	$(call PACK,libfontenc1,DEB_LIBFONTENC_V)
	$(call PACK,libfontenc-dev,DEB_LIBFONTENC_V)

	# libfontenc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfontenc{1,-dev}

.PHONY: libfontenc libfontenc-package