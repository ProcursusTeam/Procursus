ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libmatroska
LIBMATROSKA_VERSION := 1.6.3
DEB_LIBMATROSKA_V   ?= $(LIBMATROSKA_VERSION)

libmatroska-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dl.matroska.org/downloads/libmatroska/libmatroska-$(LIBMATROSKA_VERSION).tar.xz
	$(call EXTRACT_TAR,libmatroska-$(LIBMATROSKA_VERSION).tar.xz,libmatroska-$(LIBMATROSKA_VERSION),libmatroska)

ifneq ($(wildcard $(BUILD_WORK)/libmatroska/.build_complete),)
libmatroska:
	@echo "Using previously built libmatroska."
else
libmatroska: libmatroska-setup libebml
	cd $(BUILD_WORK)/libmatroska && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=ON \
		.
	+$(MAKE) -C $(BUILD_WORK)/libmatroska
	+$(MAKE) -C $(BUILD_WORK)/libmatroska install \
		DESTDIR="$(BUILD_STAGE)/libmatroska"
	+$(MAKE) -C $(BUILD_WORK)/libmatroska install \
		DESTDIR="$(BUILD_BASE)"

	touch $(BUILD_WORK)/libmatroska/.build_complete
endif

libmatroska-package: libmatroska-stage
	# libmatroska.mk Package Structure
	rm -rf $(BUILD_DIST)/libmatroska{7,-dev}
	mkdir -p $(BUILD_DIST)/libmatroska{7,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmatroska.mk Prep libmatroska7
	cp -a $(BUILD_STAGE)/libmatroska/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmatroska.7*.dylib $(BUILD_DIST)/libmatroska7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmatroska.mk Prep libmatroska-dev
	cp -a $(BUILD_STAGE)/libmatroska/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmatroska-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libmatroska/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmatroska.dylib $(BUILD_DIST)/libmatroska-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libmatroska/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libmatroska-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libmatroska/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake $(BUILD_DIST)/libmatroska-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmatroska.mk Sign
	$(call SIGN,libmatroska7,general.xml)

	# libmatroska.mk Make .debs
	$(call PACK,libmatroska7,DEB_LIBMATROSKA_V)
	$(call PACK,libmatroska-dev,DEB_LIBMATROSKA_V)

	# libmatroska.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmatroska{7,-dev}

.PHONY: libmatroska libmatroska-package
