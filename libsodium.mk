ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libsodium
LIBSODIUM_VERSION     := 1.0.18
DEB_LIBSODIUM_V       ?= $(LIBSODIUM_VERSION)

libsodium-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.libsodium.org/libsodium/releases/libsodium-$(LIBSODIUM_VERSION).tar.gz
	$(call EXTRACT_TAR,libsodium-$(LIBSODIUM_VERSION).tar.gz,libsodium-$(LIBSODIUM_VERSION),libsodium)

ifneq ($(wildcard $(BUILD_WORK)/libsodium/.build_complete),)
libsodium:
	@echo "Using previously built libsodium."
else
libsodium: libsodium-setup
	cd $(BUILD_WORK)/libsodium && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libsodium
	+$(MAKE) -C $(BUILD_WORK)/libsodium install \
		DESTDIR=$(BUILD_STAGE)/libsodium
	+$(MAKE) -C $(BUILD_WORK)/libsodium install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsodium/.build_complete
endif

libsodium-package: libsodium-stage
	# libsodium.mk Package Structure
	rm -rf $(BUILD_DIST)/libsodium{23,-dev}
	mkdir -p $(BUILD_DIST)/libsodium{23,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsodium.mk Prep libsodium
	cp -a $(BUILD_STAGE)/libsodium/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsodium.23.dylib $(BUILD_DIST)/libsodium23/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsodium.mk Prep libsodium-dev
	cp -a $(BUILD_STAGE)/libsodium/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsodium-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsodium/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libsodium.23.dylib) $(BUILD_DIST)/libsodium-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsodium.mk Sign
	$(call SIGN,libsodium23,general.xml)

	# libsodium.mk Make .debs
	$(call PACK,libsodium23,DEB_LIBSODIUM_V)
	$(call PACK,libsodium-dev,DEB_LIBSODIUM_V)

	# libsodium.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsodium{23,-dev}

.PHONY: libsodium libsodium-package
