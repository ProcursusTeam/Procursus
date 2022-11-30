ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libsmb2
LIBSMB2_VERSION := 4.0.0
DEB_LIBSMB2_V   ?= $(LIBSMB2_VERSION)

libsmb2-setup: setup
	$(call GITHUB_ARCHIVE,sahlberg,libsmb2,$(LIBSMB2_VERSION),v$(LIBSMB2_VERSION))
	$(call EXTRACT_TAR,libsmb2-$(LIBSMB2_VERSION).tar.gz,libsmb2-$(LIBSMB2_VERSION),libsmb2)
	sed -i '/DHAVE_LIBKRB5/d' $(BUILD_WORK)/libsmb2/CMakeLists.txt # NO
	mkdir -p $(BUILD_WORK)/libsmb2/build

ifneq ($(wildcard $(BUILD_WORK)/libsmb2/.build_complete),)
libsmb2:
	@echo "Using previously built libsmb2."
else
libsmb2: libsmb2-setup openssl
	cd $(BUILD_WORK)/libsmb2/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/libsmb2/build
	+$(MAKE) -C $(BUILD_WORK)/libsmb2/build install \
		DESTDIR="$(BUILD_STAGE)/libsmb2"
	$(call AFTER_BUILD,copy)
endif

libsmb2-package: libsmb2-stage
	# libsmb2.mk Package Structure
	rm -rf $(BUILD_DIST)/libsmb2-{1,dev}
	mkdir -p $(BUILD_DIST)/libsmb2-{1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsmb2.mk Prep libsmb2-1
	cp -a $(BUILD_STAGE)/libsmb2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsmb2.{1,$(LIBSMB2_VERSION)}.dylib $(BUILD_DIST)/libsmb2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsmb2.mk Prep libsmb2-dev
	cp -a $(BUILD_STAGE)/libsmb2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libsmb2.dylib,pkgconfig,cmake} $(BUILD_DIST)/libsmb2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsmb2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsmb2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsmb2.mk Sign
	$(call SIGN,libsmb2-1,general.xml)

	# libsmb2.mk Make .debs
	$(call PACK,libsmb2-1,DEB_LIBSMB2_V)
	$(call PACK,libsmb2-dev,DEB_LIBSMB2_V)

	# libsmb2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsmb2-{1,dev}

.PHONY: libsmb2 libsmb2-package
