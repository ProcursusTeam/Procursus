ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += xar
XAR_VERSION := 420
DEB_XAR_V   ?= 1.8.0.$(XAR_VERSION)+fc-6

xar-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/xar/xar-$(XAR_VERSION).tar.gz
	$(call EXTRACT_TAR,xar-$(XAR_VERSION).tar.gz,xar-$(XAR_VERSION)/xar,xar)
	$(call DO_PATCH,xar,xar,-p1)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/xar

ifneq ($(wildcard $(BUILD_WORK)/xar/.build_complete),)
xar:
	@echo "Using previously built xar."
else
xar: xar-setup openssl
	cd $(BUILD_WORK)/xar && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_header_openssl_evp_h=yes \
		ac_cv_lib_crypto_OPENSSL_init_crypto=yes \
		ac_cv_header_libxml_xmlwriter_h=yes \
		ac_cv_header_zlib_h=yes \
		ac_cv_lib_z_deflate=yes \
		ac_cv_header_bzlib_h=yes \
		ac_cv_lib_bz2_BZ2_bzCompress=yes
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/lib|$(TARGET_SYSROOT)/usr/lib|g' $(BUILD_WORK)/xar/lib/Makefile.inc
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/lib|$(TARGET_SYSROOT)/usr/lib|g' $(BUILD_WORK)/xar/src/Makefile.inc
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/include|$(TARGET_SYSROOT)/usr/include|g' $(BUILD_WORK)/xar/Makefile
	+$(MAKE) -C $(BUILD_WORK)/xar \
		CFLAGS="$(CFLAGS) -I$(BUILD_WORK)/xar/lib"
	+$(MAKE) -C $(BUILD_WORK)/xar install \
		DESTDIR=$(BUILD_STAGE)/xar
	cp -a $(BUILD_STAGE)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/xar/.build_complete
endif

xar-package: xar-stage
	# xar.mk Package Structure
	rm -rf $(BUILD_DIST)/xar $(BUILD_DIST)/libxar{1,-dev}
	mkdir -p $(BUILD_DIST)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libxar{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xar.mk Prep xar
	cp -a $(BUILD_STAGE)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xar.mk Prep libxar1
	cp -a $(BUILD_STAGE)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxar.1.dylib $(BUILD_DIST)/libxar1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xar.mk Prep libxar-dev
	cp -a $(BUILD_STAGE)/xar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libxar.1.dylib) $(BUILD_DIST)/libxar-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xar.mk Sign
	$(call SIGN,xar,general.xml)
	$(call SIGN,libxar1,general.xml)

	# xar.mk Make .debs
	$(call PACK,xar,DEB_XAR_V)
	$(call PACK,libxar1,DEB_XAR_V)
	$(call PACK,libxar-dev,DEB_XAR_V)

	# xar.mk Build cleanup
	rm -rf $(BUILD_DIST)/xar $(BUILD_DIST)/libxar{1,-dev}

.PHONY: xar xar-package
