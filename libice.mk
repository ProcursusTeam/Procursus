ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libice
LIBICE_VERSION := 1.0.10
DEB_LIBICE_V   ?= $(LIBICE_VERSION)

libice-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libICE-$(LIBICE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libICE-$(LIBICE_VERSION).tar.gz)
	$(call EXTRACT_TAR,libICE-$(LIBICE_VERSION).tar.gz,libICE-$(LIBICE_VERSION),libice)

ifneq ($(wildcard $(BUILD_WORK)/libice/.build_complete),)
libice:
	@echo "Using previously built libice."
else
libice: libice-setup xtrans xorgproto
	cd $(BUILD_WORK)/libice && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no \
		--enable-docs=no \
		--enable-specs=no
	+$(MAKE) -C $(BUILD_WORK)/libice
	+$(MAKE) -C $(BUILD_WORK)/libice install \
		DESTDIR=$(BUILD_STAGE)/libice
	+$(MAKE) -C $(BUILD_WORK)/libice install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libice/.build_complete
endif

libice-package: libice-stage
	# libice.mk Package Structure
	rm -rf $(BUILD_DIST)/libice{6,-dev}
	mkdir -p $(BUILD_DIST)/libice6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libice.mk Prep libice6
	cp -a $(BUILD_STAGE)/libice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libICE.6.dylib $(BUILD_DIST)/libice6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libice.mk Prep libice-dev
	cp -a $(BUILD_STAGE)/libice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libICE.6.dylib) $(BUILD_DIST)/libice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libice/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libice-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libice.mk Sign
	$(call SIGN,libice6,general.xml)

	# libice.mk Make .debs
	$(call PACK,libice6,DEB_LIBICE_V)
	$(call PACK,libice-dev,DEB_LIBICE_V)

	# libice.mk Build cleanup
	rm -rf $(BUILD_DIST)/libice{6,-dev}

.PHONY: libice libice-package
