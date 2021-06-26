ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxft
LIBXFT_VERSION := 2.3.3
DEB_LIBXFT_V   ?= $(LIBXFT_VERSION)

libxft-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXft-$(LIBXFT_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXft-$(LIBXFT_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXft-$(LIBXFT_VERSION).tar.gz,libXft-$(LIBXFT_VERSION),libxft)

ifneq ($(wildcard $(BUILD_WORK)/libxft/.build_complete),)
libxft:
	@echo "Using previously built libxft."
else
libxft: libxft-setup libx11 libxrender xorgproto fontconfig freetype
	cd $(BUILD_WORK)/libxft && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxft
	+$(MAKE) -C $(BUILD_WORK)/libxft install \
		DESTDIR=$(BUILD_STAGE)/libxft
	+$(MAKE) -C $(BUILD_WORK)/libxft install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxft/.build_complete
endif

libxft-package: libxft-stage
	# libxft.mk Package Structure
	rm -rf $(BUILD_DIST)/libxft{2,-dev}
	mkdir -p $(BUILD_DIST)/libxft2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxft-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxft.mk Prep libxft2
	cp -a $(BUILD_STAGE)/libxft/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXft.2*.dylib $(BUILD_DIST)/libxft2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxft.mk Prep libxft-dev
	cp -a $(BUILD_STAGE)/libxft/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXft.2*.dylib) $(BUILD_DIST)/libxft-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxft/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxft-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libxft.mk Sign
	$(call SIGN,libxft2,general.xml)

	# libxft.mk Make .debs
	$(call PACK,libxft2,DEB_LIBXFT_V)
	$(call PACK,libxft-dev,DEB_LIBXFT_V)

	# libxft.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxft{2,-dev}

.PHONY: libxft libxft-package
