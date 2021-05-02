ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libspeex
LIBSPEEX_VERSION := 1.2.0
DEB_LIBSPEEX_V   ?= $(LIBSPEEX_VERSION)

libspeex-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://downloads.us.xiph.org/releases/speex/speex-$(LIBSPEEX_VERSION).tar.gz
	$(call EXTRACT_TAR,speex-$(LIBSPEEX_VERSION).tar.gz,speex-$(LIBSPEEX_VERSION),libspeex)

ifneq ($(wildcard $(BUILD_WORK)/libspeex/.build_complete),)
libspeex:
	@echo "Using previously built libspeex."
else
libspeex: libspeex-setup libogg
	cd $(BUILD_WORK)/libspeex && autoreconf -fi
	cd $(BUILD_WORK)/libspeex && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-binaries \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/libspeex
	+$(MAKE) -C $(BUILD_WORK)/libspeex install \
		DESTDIR=$(BUILD_STAGE)/libspeex
	+$(MAKE) -C $(BUILD_WORK)/libspeex install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libspeex/.build_complete
endif

libspeex-package: libspeex-stage
	# libspeex.mk Package Structure
	rm -rf $(BUILD_DIST)/libspeex{1,-dev} \
		$(BUILD_DIST)/speex
	mkdir -p $(BUILD_DIST)/libspeex{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/speex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libspeex.mk Prep speex
	cp -a $(BUILD_STAGE)/libspeex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/speex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libspeex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/speex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libspeex.mk Prep libspeex1
	cp -a $(BUILD_STAGE)/libspeex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libspeex.1.dylib $(BUILD_DIST)/libspeex1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libspeex.mk Prep libspeex-dev
	cp -a $(BUILD_STAGE)/libspeex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libspeex.{a,dylib},pkgconfig} $(BUILD_DIST)/libspeex-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libspeex/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libspeex-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libspeex.mk Sign
	$(call SIGN,speex,general.xml)
	$(call SIGN,libspeex1,general.xml)

	# libspeex.mk Make .debs
	$(call PACK,speex,DEB_LIBSPEEX_V)
	$(call PACK,libspeex1,DEB_LIBSPEEX_V)
	$(call PACK,libspeex-dev,DEB_LIBSPEEX_V)

	# libspeex.mk Build cleanup
	rm -rf $(BUILD_DIST)/libspeex{1,-dev} \
		$(BUILD_DIST)/speex

.PHONY: libspeex libspeex-package
