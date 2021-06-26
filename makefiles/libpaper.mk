ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libpaper
LIBPAPER_VERSION := 1.1.28
DEB_LIBPAPER_V   ?= $(LIBPAPER_VERSION)

libpaper-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/libp/libpaper/libpaper_$(LIBPAPER_VERSION).tar.gz
	$(call EXTRACT_TAR,libpaper_$(LIBPAPER_VERSION).tar.gz,libpaper-$(LIBPAPER_VERSION),libpaper)

ifneq ($(wildcard $(BUILD_WORK)/libpaper/.build_complete),)
libpaper:
	@echo "Using previously built libpaper."
else
libpaper: libpaper-setup
	cd $(BUILD_WORK)/libpaper && autoreconf -fi
	cd $(BUILD_WORK)/libpaper && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpaper
	+$(MAKE) -C $(BUILD_WORK)/libpaper install \
		DESTDIR="$(BUILD_STAGE)/libpaper"
	+$(MAKE) -C $(BUILD_WORK)/libpaper install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libpaper/.build_complete
endif

libpaper-package: libpaper-stage
	# libpaper.mk Package Structure
	rm -rf $(BUILD_DIST)/libpaper{1,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libpaper{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man} \
		$(BUILD_DIST)/libpaper-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libpaper.mk Prep libpaper1
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpaper.1.dylib $(BUILD_DIST)/libpaper1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5 $(BUILD_DIST)/libpaper1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libpaper.mk Prep libpaper-dev
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libpaper.1.dylib) $(BUILD_DIST)/libpaper-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libpaper-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpaper-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libpaper.mk Prep libpaper-utils
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{s,}bin $(BUILD_DIST)/libpaper-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libpaper/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{1,8} $(BUILD_DIST)/libpaper-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libpaper.mk Sign
	$(call SIGN,libpaper1,general.xml)
	$(call SIGN,libpaper-utils,general.xml)

	# libpaper.mk Make .debs
	$(call PACK,libpaper1,DEB_LIBPAPER_V)
	$(call PACK,libpaper-dev,DEB_LIBPAPER_V)
	$(call PACK,libpaper-utils,DEB_LIBPAPER_V)

	# libpaper.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpaper{1,-dev,-utils}

.PHONY: libpaper libpaper-package
