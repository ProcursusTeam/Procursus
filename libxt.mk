ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libxt
LIBXT_VERSION := 1.2.1
DEB_LIBXT_V   ?= $(LIBXT_VERSION)

libxt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXt-$(LIBXT_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXt-$(LIBXT_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXt-$(LIBXT_VERSION).tar.gz,libXt-$(LIBXT_VERSION),libxt)

ifneq ($(wildcard $(BUILD_WORK)/libxt/.build_complete),)
libxt:
	@echo "Using previously built libxt."
else
libxt: libxt-setup libx11 libice libsm
	cd $(BUILD_WORK)/libxt && unset CPP CPPFLAGS && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no \
		--enable-specs=no \
		--disable-silent-rules
	+$(MAKE) -C $(BUILD_WORK)/libxt
	+$(MAKE) -C $(BUILD_WORK)/libxt install \
		DESTDIR=$(BUILD_STAGE)/libxt
	+$(MAKE) -C $(BUILD_WORK)/libxt install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxt/.build_complete
endif

libxt-package: libxt-stage
	# libxt.mk Package Structure
	rm -rf $(BUILD_DIST)/libxt{6,-dev}
	mkdir -p $(BUILD_DIST)/libxt6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxt.mk Prep libxt6
	cp -a $(BUILD_STAGE)/libxt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXt.6*.dylib $(BUILD_DIST)/libxt6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxt.mk Prep libxt-dev
	cp -a $(BUILD_STAGE)/libxt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXt.6*.dylib) $(BUILD_DIST)/libxt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libxt.mk Sign
	$(call SIGN,libxt6,general.xml)

	# libxt.mk Make .debs
	$(call PACK,libxt6,DEB_LIBXT_V)
	$(call PACK,libxt-dev,DEB_LIBXT_V)

	# libxt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxt{6,-dev}

.PHONY: libxt libxt-package
