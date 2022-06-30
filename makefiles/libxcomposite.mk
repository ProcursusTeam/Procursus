ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libxcomposite
LIBXCOMPOSITE_VERSION := 0.4.5
DEB_LIBXCOMPOSITE_V   ?= $(LIBXCOMPOSITE_VERSION)

libxcomposite-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXcomposite-$(LIBXCOMPOSITE_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXcomposite-$(LIBXCOMPOSITE_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXcomposite-$(LIBXCOMPOSITE_VERSION).tar.bz2,libXcomposite-$(LIBXCOMPOSITE_VERSION),libxcomposite)

ifneq ($(wildcard $(BUILD_WORK)/libxcomposite/.build_complete),)
libxcomposite:
	@echo "Using previously built libxcomposite."
else
libxcomposite: libxcomposite-setup libx11 libxext util-macros libxfixes
	cd $(BUILD_WORK)/libxcomposite && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		  --enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxcomposite
	+$(MAKE) -C $(BUILD_WORK)/libxcomposite install \
		DESTDIR=$(BUILD_STAGE)/libxcomposite
	$(call AFTER_BUILD,copy)
endif

libxcomposite-package: libxcomposite-stage
	# libxcomposite.mk Package Structure
	rm -rf $(BUILD_DIST)/libxcomposite{1,-dev}
	mkdir -p $(BUILD_DIST)/libxcomposite{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcomposite.mk Prep libxcomposite1
	cp -a $(BUILD_STAGE)/libxcomposite/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXcomposite.1.dylib $(BUILD_DIST)/libxcomposite1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcomposite.mk Prep libxcomposite-dev
	cp -a $(BUILD_STAGE)/libxcomposite/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxcomposite-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxcomposite/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libXcomposite.{dylib,a}} $(BUILD_DIST)/libxcomposite-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxcomposite.mk Sign
	$(call SIGN,libxcomposite1,general.xml)

	# libxcomposite.mk Make .debs
	$(call PACK,libxcomposite1,DEB_LIBXCOMPOSITE_V)
	$(call PACK,libxcomposite-dev,DEB_LIBXCOMPOSITE_V)

	# libxcomposite.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcomposite{1,-dev}

.PHONY: libxcomposite libxcomposite-package
