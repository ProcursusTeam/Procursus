ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libnet
LIBNET_VERSION := 1.2
DEB_LIBNET_V   ?= $(LIBNET_VERSION)

libnet-setup: setup
	$(call GITHUB_ARCHIVE,libnet,libnet,$(LIBNET_VERSION),v$(LIBNET_VERSION))
	$(call EXTRACT_TAR,libnet-$(LIBNET_VERSION).tar.gz,libnet-$(LIBNET_VERSION),libnet)

ifneq ($(wildcard $(BUILD_WORK)/libnet/.build_complete),)
libnet:
	@echo "Using previously built libnet."
else
libnet: libnet-setup
	cd $(BUILD_WORK)/libnet && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-link-layer=bpf
	+$(MAKE) -C $(BUILD_WORK)/libnet
	+$(MAKE) -C $(BUILD_WORK)/libnet install \
		DESTDIR="$(BUILD_STAGE)/libnet"
	$(call AFTER_BUILD,copy)
endif

libnet-package: libnet-stage
	# libnet.mk Package Structure
	rm -rf $(BUILD_DIST)/libnet9{,-dev}
	mkdir -p $(BUILD_DIST)/libnet9{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libnet.mk Prep libnet9
	cp -a $(BUILD_STAGE)/libnet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnet.9.dylib $(BUILD_DIST)/libnet9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libnet.mk Prep libnet9-dev
	cp -a $(BUILD_STAGE)/libnet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libnet.{a,dylib},pkgconfig} $(BUILD_DIST)/libnet9-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libnet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,bin} $(BUILD_DIST)/libnet9-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libnet.mk Sign
	$(call SIGN,libnet9,general.xml)
	$(call SIGN,libnet9-dev,general.xml)

	# libnet.mk Make .debs
	$(call PACK,libnet9,DEB_LIBNET_V)
	$(call PACK,libnet9-dev,DEB_LIBNET_V)

	# libnet.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnet9{,-dev}

.PHONY: libnet libnet-package
