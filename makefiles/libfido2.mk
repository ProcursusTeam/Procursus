ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libfido2
LIBFIDO2_VERSION := 1.7.0
DEB_LIBFIDO2_V   ?= $(LIBFIDO2_VERSION)

libfido2-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://developers.yubico.com/libfido2/Releases/libfido2-$(LIBFIDO2_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libfido2-$(LIBFIDO2_VERSION).tar.gz)
	$(call EXTRACT_TAR,libfido2-$(LIBFIDO2_VERSION).tar.gz,libfido2-$(LIBFIDO2_VERSION),libfido2)
	mkdir -p $(BUILD_WORK)/libfido2/build

ifneq ($(wildcard $(BUILD_WORK)/libfido2/.build_complete),)
libfido2:
	@echo "Using previously built libfido2."
else
libfido2: libfido2-setup libcbor openssl
	cd $(BUILD_WORK)/libfido2/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DZLIB_FOUND=1 \
		-DZLIB_LIBRARY_DIRS=$(TARGET_SYSROOT)/usr/lib/libz.1.tbd \
		-DZLIB_INCLUDE_DIRS=$(TARGET_SYSROOT)/usr/include/zlib.h \
		..
	+$(MAKE) -C $(BUILD_WORK)/libfido2/build
	+$(MAKE) -C $(BUILD_WORK)/libfido2/build install \
		DESTDIR="$(BUILD_STAGE)/libfido2"
	touch $(BUILD_WORK)/libfido2/.build_complete
endif

libfido2-package: libfido2-stage
	# libfido2.mk Package Structure
	rm -rf $(BUILD_DIST)/libfido2
	mkdir -p $(BUILD_DIST)/fido2-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){bin,man/man1} \
			$(BUILD_DIST)/libfido2{-1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){lib,include}

	# libfido2.mk Prep libfido2-1
	cp -a $(BUILD_STAGE)/libfido2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libfido2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfido2.mk Prep libfido2-dev
	cp -a $(BUILD_STAGE)/libfido2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libfido2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfido2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfido2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libfido2.mk Prep fido2-tools
	cp -a $(BUILD_STAGE)/libfido2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/fido2-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libfido2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man/man1 $(BUILD_DIST)/fido2-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man

	# libfido2.mk Sign
	$(call SIGN,libfido2-1,general.xml)
	$(call SIGN,libfido2-dev,general.xml)
	$(call SIGN,fido2-tools,general.xml)

	# libfido2.mk Make .debs
	$(call PACK,libfido2-1,DEB_LIBFIDO2_V)
	$(call PACK,libfido2-dev,DEB_LIBFIDO2_V)
	$(call PACK,fido2-tools,DEB_LIBFIDO2_V)

	# libfido2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfido2{-1,-dev}
	rm -rf $(BUILD_DIST)/fido2-tools

.PHONY: libfido2 libfido2-package
