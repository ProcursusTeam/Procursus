ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gpgme
GPGME_VERSION := 1.23.2
DEB_GPGME_V   ?= $(GPGME_VERSION)

gpgme-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://gnupg.org/ftp/gcrypt/gpgme/gpgme-$(GPGME_VERSION).tar.bz2{$(comma).sig})
	$(call PGP_VERIFY,gpgme-$(GPGME_VERSION).tar.bz2)
	$(call EXTRACT_TAR,gpgme-$(GPGME_VERSION).tar.bz2,gpgme-$(GPGME_VERSION),gpgme)
	sed -i 's/-keep_private_externs -nostdlib/-keep_private_externs $(PLATFORM_VERSION_MIN) -nostdlib/g' $(BUILD_WORK)/gpgme/configure

ifneq ($(wildcard $(BUILD_WORK)/gpgme/.build_complete),)
gpgme:
	@echo "Using previously built gpgme."
else
gpgme: gpgme-setup gnupg libassuan libgpg-error
	cd $(BUILD_WORK)/gpgme && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libassuan-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-libgpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-glibtest \
		--disable-gpgconf-test \
		--disable-gpg-test \
		--disable-gpgsm-test \
		--disable-g13-test
	+printf 'all:\nclean:\ninstall:\n.PHONY: all clean install\n' > $(BUILD_WORK)/gpgme/lang/python/tests/Makefile
	+$(MAKE) -C $(BUILD_WORK)/gpgme \
		CPATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include:$(TARGET_SYSROOT)/usr/include"
	+$(MAKE) -C $(BUILD_WORK)/gpgme install \
		DESTDIR=$(BUILD_STAGE)/gpgme \
		CPATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include:$(TARGET_SYSROOT)/usr/include"
	$(call AFTER_BUILD,copy)
endif

gpgme-package: gpgme-stage
	# gpgme.mk Package Structure
	rm -rf $(BUILD_DIST)/libgpgme{11,-dev,pp6,pp-dev}
	mkdir -p $(BUILD_DIST)/libgpgme11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
			$(BUILD_DIST)/libgpgme-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
			$(BUILD_DIST)/libgpgmepp6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
			$(BUILD_DIST)/libgpgmepp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include}

	# gpgme.mk Prep gpgme
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgpgme.11.dylib $(BUILD_DIST)/libgpgme11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libgpgme-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gpgme.h $(BUILD_DIST)/libgpgme-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgpgme.dylib,pkgconfig} $(BUILD_DIST)/libgpgme-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgpgmepp.6.dylib $(BUILD_DIST)/libgpgmepp6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gpgme++ $(BUILD_DIST)/libgpgmepp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/gpgme/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgpgmepp.dylib,cmake} $(BUILD_DIST)/libgpgmepp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gpgme.mk Sign
	$(call SIGN,libgpgme-dev,general.xml)
	$(call SIGN,libgpgme11,general.xml)
	$(call SIGN,libgpgmepp6,general.xml)

	# gpgme.mk Make .debs
	$(call PACK,libgpgme11,DEB_GPGME_V)
	$(call PACK,libgpgme-dev,DEB_GPGME_V)
	$(call PACK,libgpgmepp6,DEB_GPGME_V)
	$(call PACK,libgpgmepp-dev,DEB_GPGME_V)

	# gpgme.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgpgme{11,-dev,pp6,pp-dev}

.PHONY: gpgme gpgme-package
