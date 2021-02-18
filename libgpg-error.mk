ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS        += libgpg-error
LIBGPG-ERROR_VERSION := 1.41
DEB_LIBGPG-ERROR_V   ?= $(LIBGPG-ERROR_VERSION)-1

ifneq (,$(findstring aarch64,$(GNU_HOST_TRIPLE)))
        GPG_SCHEME := aarch64-apple-darwin
else ifneq (,$(findstring arm,$(GNU_HOST_TRIPLE)))
        GPG_SCHEME := arm-apple-darwin
else
        $(error Host triple $(GNU_HOST_TRIPLE) isn't supported)
endif

libgpg-error-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libgpg-error-$(LIBGPG-ERROR_VERSION).tar.bz2,libgpg-error-$(LIBGPG-ERROR_VERSION),libgpg-error)

ifneq ($(wildcard $(BUILD_WORK)/libgpg-error/.build_complete),)
libgpg-error:
	@echo "Using previously built libgpg-error."
else
libgpg-error: libgpg-error-setup
	$(SED) -i '/{"armv7-unknown-linux-gnueabihf"  },/a \ \ \ \ {"$(GNU_HOST_TRIPLE)",  "$(GPG_SCHEME)" },' $(BUILD_WORK)/libgpg-error/src/mkheader.c
	cd $(BUILD_WORK)/libgpg-error && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-nls
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_STAGE)/libgpg-error
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_BASE)	
	touch $(BUILD_WORK)/libgpg-error/.build_complete
endif

libgpg-error-package: libgpg-error-stage
	# libgpg-error.mk Package Structure
	rm -rf $(BUILD_DIST)/{libgpg-error{0,-dev},gpgrt-tools}
	mkdir -p $(BUILD_DIST)/libgpg-error{0,-dev}/usr/lib
	mkdir -p $(BUILD_DIST)/gpgrt-tools/usr
	
	# libgpg-error.mk Prep libgpg-error
	cp -a $(BUILD_STAGE)/libgpg-error/usr/lib/libgpg-error.0.dylib $(BUILD_DIST)/libgpg-error0/usr/lib
	cp -a $(BUILD_STAGE)/libgpg-error/usr/include $(BUILD_DIST)/libgpg-error-dev/usr
	cp -a $(BUILD_STAGE)/libgpg-error/usr/lib/{libgpg-error.dylib,pkgconfig} $(BUILD_DIST)/libgpg-error-dev/usr/lib
	cp -a $(BUILD_STAGE)/libgpg-error/usr/{bin,share} $(BUILD_DIST)/gpgrt-tools/usr
	
	# libgpg-error.mk Sign
	$(call SIGN,libgpg-error0,general.xml)
	$(call SIGN,gpgrt-tools,general.xml)
	
	# libgpg-error.mk Make .debs
	$(call PACK,libgpg-error0,DEB_LIBGPG-ERROR_V)
	$(call PACK,libgpg-error-dev,DEB_LIBGPG-ERROR_V)
	$(call PACK,gpgrt-tools,DEB_LIBGPG-ERROR_V)
	
	# libgpg-error.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libgpg-error{0,-dev},gpgrt-tools}

.PHONY: libgpg-error libgpg-error-package
