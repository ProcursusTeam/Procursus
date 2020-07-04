ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += xar
XAR_VERSION := 1.6.1
DEB_XAR_V   ?= $(XAR_VERSION)

xar-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/downloads/mackyle/xar/xar-$(XAR_VERSION).tar.gz
	$(call EXTRACT_TAR,xar-$(XAR_VERSION).tar.gz,xar-$(XAR_VERSION),xar)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/xar

ifneq ($(wildcard $(BUILD_WORK)/xar/.build_complete),)
xar:
	@echo "Using previously built xar."
else
xar: xar-setup xz openssl
	cd $(BUILD_WORK)/xar && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-static=no \
		ac_cv_header_libxml_xmlwriter_h=yes \
		ac_cv_header_openssl_evp_h=yes \
		ac_cv_lib_crypto_OpenSSL_add_all_ciphers=yes \
		ac_cv_header_zlib_h=yes \
		ac_cv_lib_z_deflate=yes
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/lib|$(TARGET_SYSROOT)/usr/lib|g' $(BUILD_WORK)/xar/lib/Makefile.inc
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/lib|$(TARGET_SYSROOT)/usr/lib|g' $(BUILD_WORK)/xar/src/Makefile.inc
	$(SED) -i 's|$(MACOSX_SYSROOT)/usr/include|$(TARGET_SYSROOT)/usr/include|g' $(BUILD_WORK)/xar/Makefile
	+$(MAKE) -C $(BUILD_WORK)/xar
	+$(MAKE) -C $(BUILD_WORK)/xar install \
		DESTDIR=$(BUILD_STAGE)/xar
	+$(MAKE) -C $(BUILD_WORK)/xar install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xar/.build_complete
endif

xar-package: xar-stage
	# xar.mk Package Structure
	rm -rf $(BUILD_DIST)/xar
	mkdir -p $(BUILD_DIST)/xar
	
	# xar.mk Prep xar
	cp -a $(BUILD_STAGE)/xar/usr $(BUILD_DIST)/xar
	
	# xar.mk Sign
	$(call SIGN,xar,general.xml)
	
	# xar.mk Make .debs
	$(call PACK,xar,DEB_XAR_V)
	
	# xar.mk Build cleanup
	rm -rf $(BUILD_DIST)/xar

.PHONY: xar xar-package
