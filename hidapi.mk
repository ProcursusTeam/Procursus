ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += hidapi
HIDAPI_VERSION := 0.9.0
DEB_HIDAPI_V   ?= $(HIDAPI_VERSION)

hidapi-setup: setup
	$(call GITHUB_ARCHIVE,libusb,hidapi,$(HIDAPI_VERSION),hidapi-$(HIDAPI_VERSION))
	$(call EXTRACT_TAR,hidapi-$(HIDAPI_VERSION).tar.gz,hidapi-hidapi-$(HIDAPI_VERSION),hidapi)

ifneq ($(wildcard $(BUILD_WORK)/hidapi/.build_complete),)
hidapi:
	@echo "Using previously built hidapi."
else
hidapi: hidapi-setup
	cd $(BUILD_WORK)/hidapi && ./bootstrap
	cd $(BUILD_WORK)/hidapi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/hidapi install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_STAGE)/hidapi"
	+$(MAKE) -C $(BUILD_WORK)/hidapi install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/hidapi/.build_complete
endif

hidapi-package: hidapi-stage
	# hidapi.mk Package Structure
	rm -rf $(BUILD_DIST)/libhidapi{0,-dev}
	mkdir -p $(BUILD_DIST)/libhidapi{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# hidapi.mk Prep libhidapi0
	cp -a $(BUILD_STAGE)/hidapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhidapi.0.dylib $(BUILD_DIST)/libhidapi0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# hidapi.mk Prep libhidapi-dev
	cp -a $(BUILD_STAGE)/hidapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libhidapi.{a,dylib}} $(BUILD_DIST)/libhidapi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/hidapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libhidapi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# hidapi.mk Sign
	$(call SIGN,libhidapi0,general.xml)

	# hidapi.mk Make .debs
	$(call PACK,libhidapi0,DEB_HIDAPI_V)
	$(call PACK,libhidapi-dev,DEB_HIDAPI_V)

	# hidapi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libhidapi{0,-dev}

.PHONY: hidapi hidapi-package
