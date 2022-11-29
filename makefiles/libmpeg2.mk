ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libmpeg2
LIBMPEG2_VERSION := 0.5.1
DEB_LIBMPEG2_V   ?= $(LIBMPEG2_VERSION)

libmpeg2-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://libmpeg2.sourceforge.io/files/libmpeg2-$(LIBMPEG2_VERSION).tar.gz)
	$(call EXTRACT_TAR,libmpeg2-$(LIBMPEG2_VERSION).tar.gz,libmpeg2-$(LIBMPEG2_VERSION),libmpeg2)

ifneq ($(wildcard $(BUILD_WORK)/libmpeg2/.build_complete),)
libmpeg2:
	@echo "Using previously built libmpeg2."
else
libmpeg2: libmpeg2-setup libx11 libxext
	cd $(BUILD_WORK)/libmpeg2 && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CFLAGS="-std=gnu89 $(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/libmpeg2
	+$(MAKE) -C $(BUILD_WORK)/libmpeg2 install \
		DESTDIR=$(BUILD_STAGE)/libmpeg2
	$(call AFTER_BUILD,copy)
endif

libmpeg2-package: libmpeg2-stage
	# libmpeg2.mk Package Structure
	rm -rf $(BUILD_DIST)/{libmpeg2-4{,-dev},mpeg2dec}
	mkdir -p $(BUILD_DIST)/libmpeg2-4{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/mpeg2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# libmpeg2.mk Prep libmpeg2-4
	cp -a $(BUILD_STAGE)/libmpeg2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpeg2{,convert}.0.dylib $(BUILD_DIST)/libmpeg2-4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpeg2.mk Prep libmpeg2-4-dev
	cp -a $(BUILD_STAGE)/libmpeg2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmpeg2-4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libmpeg2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libmpeg2{,convert}.{dylib,a}} $(BUILD_DIST)/libmpeg2-4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpeg2.mk Prep mpeg2dec
	cp -a $(BUILD_STAGE)/libmpeg2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{mpeg2dec,extract_mpeg2} $(BUILD_DIST)/mpeg2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libmpeg2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{mpeg2dec,extract_mpeg2}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/mpeg2dec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# libmpeg2.mk Sign
	$(call SIGN,libmpeg2-4,general.xml)
	$(call SIGN,mpeg2dec,general.xml)

	# libmpeg2.mk Make .debs
	$(call PACK,libmpeg2-4,DEB_LIBMPEG2_V)
	$(call PACK,libmpeg2-4-dev,DEB_LIBMPEG2_V)
	$(call PACK,mpeg2dec,DEB_LIBMPEG2_V)

	# libmpeg2.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libmpeg2-4{,-dev},mpeg2dec}

.PHONY: libmpeg2 libmpeg2-package
