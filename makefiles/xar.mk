ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += xar
XAR_VERSION := 487.100.1
DEB_XAR_V   ?= 1.8.0.$(XAR_VERSION)-1

xar-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,xar,$(XAR_VERSION),xar-$(XAR_VERSION))
	$(call EXTRACT_TAR,xar-$(XAR_VERSION).tar.gz,xar-xar-$(XAR_VERSION)/xar,xar)
#	XXX: Patches stolen from MacPorts (who mostly stole them from other spots)
	$(call DO_PATCH,xar,xar,-p0)
	cp -a $(BUILD_MISC)/config.sub $(BUILD_WORK)/xar

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
	printf '#!/bin/sh\nexit 0;\n' > $(BUILD_WORK)/xar/config.status
	sed -i 's|$(MACOSX_SYSROOT)|$(TARGET_SYSROOT)|g' $(BUILD_WORK)/xar/{{lib,src}/Makefile.inc,Makefile}
	+$(MAKE) -C $(BUILD_WORK)/xar \
		CFLAGS="$(CFLAGS) -I$(BUILD_WORK)/xar/lib"
	+$(MAKE) -C $(BUILD_WORK)/xar install \
		DESTDIR=$(BUILD_STAGE)/xar
	$(call AFTER_BUILD,copy)
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
