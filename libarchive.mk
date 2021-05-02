ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libarchive
LIBARCHIVE_VERSION := 3.5.1
DEB_LIBARCHIVE_V   ?= $(LIBARCHIVE_VERSION)

libarchive-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.libarchive.org/downloads/libarchive-$(LIBARCHIVE_VERSION).tar.xz
	$(call EXTRACT_TAR,libarchive-$(LIBARCHIVE_VERSION).tar.xz,libarchive-$(LIBARCHIVE_VERSION),libarchive)

ifneq ($(wildcard $(BUILD_WORK)/libarchive/.build_complete),)
libarchive:
	@echo "Using previously built libarchive."
else
libarchive: libarchive-setup lz4 liblzo2 zstd xz nettle
	cd $(BUILD_WORK)/libarchive && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--without-openssl \
		--with-nettle \
		--with-lzo2 \
		--enable-bsdtar=shared \
		--enable-bsdcpio=shared \
		--enable-bsdcat=shared
	+$(MAKE) -C $(BUILD_WORK)/libarchive
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_STAGE)/libarchive"
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libarchive/.build_complete
endif

libarchive-package: libarchive-stage
	# libarchive.mk Package Structure
	rm -rf $(BUILD_DIST)/libarchive{13,-tools,-dev}
	mkdir -p $(BUILD_DIST)/libarchive13/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libarchive-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	mkdir -p $(BUILD_DIST)/libarchive-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man}

	# libarchive.mk Prep libarchive13
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libarchive.*.dylib $(BUILD_DIST)/libarchive13/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libarchive.mk Prep libarchive-tools
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libarchive-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/libarchive-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/

	# libarchive.mk Prep libarchive-dev
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libarchive-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libarchive.dylib,pkgconfig} $(BUILD_DIST)/libarchive-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libarchive/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{3,5} $(BUILD_DIST)/libarchive-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libarchive.mk Sign
	$(call SIGN,libarchive13,general.xml)
	$(call SIGN,libarchive-tools,general.xml)

	# libarchive.mk Make .debs
	$(call PACK,libarchive13,DEB_LIBARCHIVE_V)
	$(call PACK,libarchive-tools,DEB_LIBARCHIVE_V)
	$(call PACK,libarchive-dev,DEB_LIBARCHIVE_V)

	# libarchive.mk Build cleanup
	rm -rf $(BUILD_DIST)/libarchive{13,-dev,-tools}

.PHONY: libarchive libarchive-package
