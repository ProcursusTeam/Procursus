ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libspeex
LIBSPEEX_VERSION := 1.2.0
DEB_LIBSPEEX_V   ?= $(LIBSPEEX_VERSION)

libspeex-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.osuosl.org/pub/xiph/releases/speex/speex-$(LIBSPEEX_VERSION).tar.gz
	$(call EXTRACT_TAR,speex-$(LIBSPEEX_VERSION).tar.gz,speex-$(LIBSPEEX_VERSION),libspeex)

ifneq ($(wildcard $(BUILD_WORK)/libspeex/.build_complete),)
libspeex:
	@echo "Using previously built libspeex."
else
libspeex: libspeex-setup libogg
	cd $(BUILD_WORK)/libspeex && autoreconf -fi
	cd $(BUILD_WORK)/libspeex && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
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
	mkdir -p $(BUILD_DIST)/libspeex{1,-dev}/usr/lib \
		$(BUILD_DIST)/speex/usr/share
	
	# libspeex.mk Prep speex
	cp -a $(BUILD_STAGE)/libspeex/usr/bin $(BUILD_DIST)/speex/usr
	cp -a $(BUILD_STAGE)/libspeex/usr/share/man $(BUILD_DIST)/speex/usr/share
	
	# libspeex.mk Prep libspeex1
	cp -a $(BUILD_STAGE)/libspeex/usr/lib/libspeex.1.dylib $(BUILD_DIST)/libspeex1/usr/lib
	
	# libspeex.mk Prep libspeex-dev
	cp -a $(BUILD_STAGE)/libspeex/usr/lib/{libspeex.{a,dylib},pkgconfig} $(BUILD_DIST)/libspeex-dev/usr/lib
	cp -a $(BUILD_STAGE)/libspeex/usr/include $(BUILD_DIST)/libspeex-dev/usr
	
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
