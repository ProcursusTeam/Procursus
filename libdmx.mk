ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libdmx
LIBDMX_VERSION := 1.1.4
DEB_LIBDMX_V   ?= $(LIBDMX_VERSION)

libdmx-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libdmx-$(LIBDMX_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libdmx-$(LIBDMX_VERSION).tar.gz)
	$(call EXTRACT_TAR,libdmx-$(LIBDMX_VERSION).tar.gz,libdmx-$(LIBDMX_VERSION),libdmx)

ifneq ($(wildcard $(BUILD_WORK)/libdmx/.build_complete),)
libdmx:
	@echo "Using previously built libdmx."
else
libdmx: libdmx-setup libx11 libxext
	cd $(BUILD_WORK)/libdmx && unset CPP CPPFLAGS && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no \
		--disable-silent-rules
	+$(MAKE) -C $(BUILD_WORK)/libdmx
	+$(MAKE) -C $(BUILD_WORK)/libdmx install \
		DESTDIR=$(BUILD_STAGE)/libdmx
	+$(MAKE) -C $(BUILD_WORK)/libdmx install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libdmx/.build_complete
endif

libdmx-package: libdmx-stage
	# libdmx.mk Package Structure
	rm -rf $(BUILD_DIST)/libdmx{1,-dev}
	mkdir -p $(BUILD_DIST)/libdmx1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libdmx-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libdmx.mk Prep libdmx1
	cp -a $(BUILD_STAGE)/libdmx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdmx.1.dylib $(BUILD_DIST)/libdmx1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libdmx.mk Prep libdmx-dev
	cp -a $(BUILD_STAGE)/libdmx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libdmx.1.dylib) $(BUILD_DIST)/libdmx-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libdmx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libdmx-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libdmx.mk Sign
	$(call SIGN,libdmx1,general.xml)

	# libdmx.mk Make .debs
	$(call PACK,libdmx1,DEB_LIBDMX_V)
	$(call PACK,libdmx-dev,DEB_LIBDMX_V)

	# libdmx.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdmx{1,-dev}

.PHONY: libdmx libdmx-package
