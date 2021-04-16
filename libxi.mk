ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libxi
LIBXI_VERSION := 1.7.10
DEB_LIBXI_V   ?= $(LIBXI_VERSION)

libxi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXi-$(LIBXI_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXi-$(LIBXI_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXi-$(LIBXI_VERSION).tar.gz,libXi-$(LIBXI_VERSION),libxi)

ifneq ($(wildcard $(BUILD_WORK)/libxi/.build_complete),)
libxi:
	@echo "Using previously built libxi."
else
libxi: libxi-setup libx11 xorgproto libxext libxfixes
	cd $(BUILD_WORK)/libxi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no \
		--enable-docs=no \
		--enable-specs=no
	+$(MAKE) -C $(BUILD_WORK)/libxi
	+$(MAKE) -C $(BUILD_WORK)/libxi install \
		DESTDIR=$(BUILD_STAGE)/libxi
	+$(MAKE) -C $(BUILD_WORK)/libxi install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxi/.build_complete
endif

libxi-package: libxi-stage
	# libxi.mk Package Structure
	rm -rf $(BUILD_DIST)/libxi{6,-dev}
	mkdir -p $(BUILD_DIST)/libxi6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libxi.mk Prep libxi6
	cp -a $(BUILD_STAGE)/libxi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXi.6.dylib $(BUILD_DIST)/libxi6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxi.mk Prep libxi-dev
	cp -a $(BUILD_STAGE)/libxi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXi.6.dylib) $(BUILD_DIST)/libxi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxi.mk Sign
	$(call SIGN,libxi6,general.xml)

	# libxi.mk Make .debs
	$(call PACK,libxi6,DEB_LIBXI_V)
	$(call PACK,libxi-dev,DEB_LIBXI_V)

	# libxi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxi{6,-dev}

.PHONY: libxi libxi-package
