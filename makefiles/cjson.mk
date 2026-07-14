ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libcjson
LIBCJSON_VERSION := 1.7.14
DEB_LIBCJSON_V   ?= $(LIBCJSON_VERSION)

libcjson-setup: setup
	$(call GITHUB_ARCHIVE,DaveGamble,cJSON,$(LIBCJSON_VERSION),v$(LIBCJSON_VERSION))
	$(call EXTRACT_TAR,cJSON-$(LIBCJSON_VERSION).tar.gz,cJSON-$(LIBCJSON_VERSION),libcjson)
	mkdir -p $(BUILD_WORK)/libcjson/build

ifneq ($(wildcard $(BUILD_WORK)/libcjson/.build_complete),)
libcjson:
	@echo "Using previously built libcjson."
else
libcjson: libcjson-setup
	cd $(BUILD_WORK)/libcjson/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_CJSON_UTILS=ON \
		-DENABLE_CJSON_TEST=OFF \
		-DBUILD_SHARED_AND_STATIC_LIBS=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/libcjson/build
	+$(MAKE) -C $(BUILD_WORK)/libcjson/build install \
		DESTDIR="$(BUILD_STAGE)/libcjson"
	+$(MAKE) -C $(BUILD_WORK)/libcjson/build install \
		DESTDIR="$(BUILD_BASE)"
	$(call AFTER_BUILD)
endif

libcjson-package: libcjson-stage
	# libcjson.mk Package Structure
	rm -rf $(BUILD_DIST)/libcjson{1,-dev}
	mkdir -p $(BUILD_DIST)/libcjson{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcjson.mk Prep libcjson1
	cp -a $(BUILD_STAGE)/libcjson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcjson{,_utils}.{$(LIBCJSON_VERSION),1}.dylib $(BUILD_DIST)/libcjson1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libcjson.mk Prep libcjson-dev
	cp -a $(BUILD_STAGE)/libcjson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcjson-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcjson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{cmake,pkgconfig} $(BUILD_DIST)/libcjson-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcjson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcjson{,_utils}.{dylib,a} $(BUILD_DIST)/libcjson-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcjson.mk Sign
	$(call SIGN,libcjson1,general.xml)
	
	# libcjson.mk Make .debs
	$(call PACK,libcjson1,DEB_LIBCJSON_V)
	$(call PACK,libcjson-dev,DEB_LIBCJSON_V)
	
	# libcjson.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcjson{1,-dev}

.PHONY: libcjson libcjson-package
