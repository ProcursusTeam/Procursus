ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS     += libxcrypt
LIBXCRYPT_VERSION := 4.4.17
DEB_LIBXCRYPT_V   ?= $(LIBXCRYPT_VERSION)

libxcrypt-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libxcrypt-$(LIBXCRYPT_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/libxcrypt-$(LIBXCRYPT_VERSION).tar.gz https://github.com/besser82/libxcrypt/archive/v$(LIBXCRYPT_VERSION).tar.gz
	$(call EXTRACT_TAR,libxcrypt-$(LIBXCRYPT_VERSION).tar.gz,libxcrypt-$(LIBXCRYPT_VERSION),libxcrypt)

ifneq ($(wildcard $(BUILD_WORK)/libxcrypt/.build_complete),)
libxcrypt:
	@echo "Using previously built libxcrypt."
else
libxcrypt: libxcrypt-setup
	cd $(BUILD_WORK)/libxcrypt && autoreconf -iv
	cd $(BUILD_WORK)/libxcrypt && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt install \
		DESTDIR=$(BUILD_STAGE)/libxcrypt
	+$(MAKE) -C $(BUILD_WORK)/libxcrypt install \
		DESTDIR=$(BUILD_BASE)	
	touch $(BUILD_WORK)/libxcrypt/.build_complete
endif

libxcrypt-package: libxcrypt-stage
	# libxcrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}
	mkdir -p $(BUILD_DIST)/libcrypt{2,-dev}/usr/lib
	
	# libxcrypt.mk Prep libxcrypt
	cp -a $(BUILD_STAGE)/libxcrypt/usr/lib/libcrypt.2.dylib $(BUILD_DIST)/libcrypt2/usr/lib
	cp -a $(BUILD_STAGE)/libxcrypt/usr/include $(BUILD_DIST)/libcrypt-dev/usr
	cp -a $(BUILD_STAGE)/libxcrypt/usr/lib/{libcrypt.{a,dylib},pkgconfig} $(BUILD_DIST)/libcrypt-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxcrypt/usr/share $(BUILD_DIST)/libcrypt-dev/usr
	
	# libxcrypt.mk Sign
	$(call SIGN,libcrypt2,general.xml)
	
	# libxcrypt.mk Make .debs
	$(call PACK,libcrypt2,DEB_LIBXCRYPT_V)
	$(call PACK,libcrypt-dev,DEB_LIBXCRYPT_V)
	
	# libxcrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcrypt{2,-dev}

.PHONY: libxcrypt libxcrypt-package

endif # ($(MEMO_TARGET),darwin-\*)