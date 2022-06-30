ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxvmc
LIBXVMC_VERSION := 1.0.13
DEB_LIBXVMC_V   ?= $(LIBXVMC_VERSION)

libxvmc-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXvMC-$(LIBXVMC_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,libXvMC-$(LIBXVMC_VERSION).tar.xz)
	$(call EXTRACT_TAR,libXvMC-$(LIBXVMC_VERSION).tar.xz,libXvMC-$(LIBXVMC_VERSION),libxvmc)

ifneq ($(wildcard $(BUILD_WORK)/libxvmc/.build_complete),)
libxvmc:
	@echo "Using previously built libxvmc."
else
libxvmc: libxvmc-setup libx11 libxext xorgproto libxv
	cd $(BUILD_WORK)/libxvmc && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		  --enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxvmc
	+$(MAKE) -C $(BUILD_WORK)/libxvmc install \
		DESTDIR=$(BUILD_STAGE)/libxvmc
	$(call AFTER_BUILD,copy)
endif

libxvmc-package: libxvmc-stage
	# libxvmc.mk Package Structure
	rm -rf $(BUILD_DIST)/libxvmc{1,-dev}
	mkdir -p $(BUILD_DIST)/libxvmc{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxvmc.mk Prep libxvmc1
	cp -a $(BUILD_STAGE)/libxvmc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXvMC.1.dylib $(BUILD_DIST)/libxvmc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxvmc.mk Prep libxvmc-dev
	cp -a $(BUILD_STAGE)/libxvmc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxvmc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxvmc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libXvMC.{dylib,a}} $(BUILD_DIST)/libxvmc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxvmc.mk Sign
	$(call SIGN,libxvmc1,general.xml)

	# libxvmc.mk Make .debs
	$(call PACK,libxvmc1,DEB_LIBXVMC_V)
	$(call PACK,libxvmc-dev,DEB_LIBXVMC_V)

	# libxvmc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxvmc{1,-dev}

.PHONY: libxvmc libxvmc-package
