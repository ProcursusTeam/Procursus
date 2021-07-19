ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libcbor
LIBCBOR_VERSION := 0.8.0
DEB_LIBCBOR_V   ?= $(LIBCBOR_VERSION)

libcbor-setup: setup
	$(call GITHUB_ARCHIVE,PJK,libcbor,$(LIBCBOR_VERSION),v$(LIBCBOR_VERSION))
	$(call EXTRACT_TAR,libcbor-$(LIBCBOR_VERSION).tar.gz,libcbor-$(LIBCBOR_VERSION),libcbor)
	mkdir -p $(BUILD_WORK)/libcbor/build

ifneq ($(wildcard $(BUILD_WORK)/libcbor/.build_complete),)
libcbor:
	@echo "Using previously built libcbor."
else
libcbor: libcbor-setup
	cd $(BUILD_WORK)/libcbor/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DWITH_EXAMPLES=OFF \
		-DBUILD_SHARED_LIBS=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/libcbor/build
	+$(MAKE) -C $(BUILD_WORK)/libcbor/build install \
		DESTDIR="$(BUILD_STAGE)/libcbor"
	touch $(BUILD_WORK)/libcbor/.build_complete
endif

libcbor-package: libcbor-stage
	# libcbor.mk Package Structure
	rm -rf $(BUILD_DIST)/libcbor{0,-dev}
	mkdir -p $(BUILD_DIST)/libcbor0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		 $(BUILD_DIST)/libcbor-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/cbor,lib/pkgconfig}
	# libcbor.mk Prep libcbor0
	cp -a $(BUILD_STAGE)/libcbor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcbor{.dylib,.0.8.dylib,.0.8.0.dylib} $(BUILD_DIST)/libcbor0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libcbor.mk Prep libcbor-dev
	cp -a $(BUILD_STAGE)/libcbor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcbor-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcbor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libcbor.pc $(BUILD_DIST)/libcbor-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libcbor.mk Sign
	$(call SIGN,libcbor0,general.xml)
	$(call SIGN,libcbor-dev,general.xml)

	# libcbor.mk Make .debs
	$(call PACK,libcbor0,DEB_LIBCBOR_V)
	$(call PACK,libcbor-dev,DEB_LIBCBOR_V)

	# libcbor.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcbor{0,-dev}

.PHONY: libcbor libcbor-package
