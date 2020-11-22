ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gpgme
GPGME_VERSION := 1.15.0
DEB_GPGME_V   ?= $(GPGME_VERSION)

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
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-libassuan-prefix=$(BUILD_BASE)/usr \
		--with-libgpg-error-prefix=$(BUILD_BASE)/usr
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
	mkdir -p $(BUILD_DIST)/libgpgme11/usr/lib \
			$(BUILD_DIST)/libgpgme-dev/usr/{lib,include} \
			$(BUILD_DIST)/libgpgmepp6/usr/lib \
			$(BUILD_DIST)/libgpgmepp-dev/usr/{lib,include}
	
	# gpgme.mk Prep gpgme
	cp -a $(BUILD_STAGE)/gpgme/usr/lib/libgpgme.11.dylib $(BUILD_DIST)/libgpgme11/usr/lib
	cp -a $(BUILD_STAGE)/gpgme/usr/{bin,share} $(BUILD_DIST)/libgpgme-dev/usr/
	cp -a $(BUILD_STAGE)/gpgme/usr/include/gpgme.h $(BUILD_DIST)/libgpgme-dev/usr/include
	cp -a $(BUILD_STAGE)/gpgme/usr/lib/{libgpgme.dylib,pkgconfig} $(BUILD_DIST)/libgpgme-dev/usr/lib
	cp -a $(BUILD_STAGE)/gpgme/usr/lib/libgpgmepp.6.dylib $(BUILD_DIST)/libgpgmepp6/usr/lib
	cp -a $(BUILD_STAGE)/gpgme/usr/include/gpgme++ $(BUILD_DIST)/libgpgmepp-dev/usr/include
	cp -a $(BUILD_STAGE)/gpgme/usr/lib/{libgpgmepp.dylib,cmake} $(BUILD_DIST)/libgpgmepp-dev/usr/lib
	
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
