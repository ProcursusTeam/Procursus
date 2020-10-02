ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libscrypt
LIBSCRYPT_VERSION := 1.21
DEB_LIBSCRYPT_V   ?= $(LIBSCRYPT_VERSION)

libscrypt-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libscrypt-$(LIBSCRYPT_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libscrypt-$(LIBSCRYPT_VERSION).tar.gz \
			https://github.com/technion/libscrypt/archive/v$(LIBSCRYPT_VERSION).tar.gz
	$(call EXTRACT_TAR,libscrypt-$(LIBSCRYPT_VERSION).tar.gz,libscrypt-$(LIBSCRYPT_VERSION),libscrypt)

ifneq ($(wildcard $(BUILD_WORK)/libscrypt/.build_complete),)
libscrypt:
	@echo "Using previously built libscrypt."
else
libscrypt: libscrypt-setup
	$(MAKE) -C $(BUILD_WORK)/libscrypt install-osx install-static \
		DESTDIR=$(BUILD_STAGE)/libscrypt \
		PREFIX=/usr \
		-j1
	$(MAKE) -C $(BUILD_WORK)/libscrypt install-osx install-static \
		DESTDIR=$(BUILD_BASE) \
		PREFIX=/usr \
		-j1
	touch $(BUILD_WORK)/libscrypt/.build_complete
endif

libscrypt-package: libscrypt-stage
	# libscrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libscrypt{0,-dev}
	mkdir -p \
		$(BUILD_DIST)/libscrypt0/usr/lib \
		$(BUILD_DIST)/libscrypt-dev/usr/lib

	# libscrypt.mk Prep libscrypt0
	cp -a $(BUILD_STAGE)/libscrypt/usr/lib/libscrypt.0.dylib $(BUILD_DIST)/libscrypt0/usr/lib/

	# libscrypt.mk Prep libscrypt-dev
	cp -a $(BUILD_STAGE)/libscrypt/usr/lib/libscrypt.{a,dylib} $(BUILD_DIST)/libscrypt-dev/usr/lib
	cp -a $(BUILD_STAGE)/libscrypt/usr/include $(BUILD_DIST)/libscrypt-dev/usr


	# libscrypt.mk Sign
	$(call SIGN,libscrypt0,general.xml)

	# libscrypt.mk Make .debs
	$(call PACK,libscrypt0,DEB_LIBSCRYPT_V)
	$(call PACK,libscrypt-dev,DEB_LIBSCRYPT_V)

	# libscrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libscrypt{0,-dev}

.PHONY: libscrypt libscrypt-package
