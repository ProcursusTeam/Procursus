ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gpgme
GPGME_VERSION := 1.15.1
DEB_GPGME_V   ?= $(GPGME_VERSION)-1

gpgme-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/gpgme/gpgme-$(GPGME_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,gpgme-$(GPGME_VERSION).tar.bz2)
	$(call EXTRACT_TAR,gpgme-$(GPGME_VERSION).tar.bz2,gpgme-$(GPGME_VERSION),gpgme)

ifneq ($(wildcard $(BUILD_WORK)/gpgme/.build_complete),)
gpgme:
	@echo "Using previously built gpgme."
else
gpgme: gpgme-setup gnupg libassuan libgpg-error
	cd $(BUILD_WORK)/gpgme && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libassuan-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-libgpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/gpgme
	+$(MAKE) -C $(BUILD_WORK)/gpgme install \
		DESTDIR=$(BUILD_STAGE)/gpgme
	+$(MAKE) -C $(BUILD_WORK)/gpgme install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gpgme/.build_complete
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
