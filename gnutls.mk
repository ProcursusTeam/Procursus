ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += gnutls
DOWNLOAD       += https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-$(GNUTLS_VERSION).tar.xz
GNUTLS_VERSION := 3.6.13
DEB_GNUTLS_V   ?= $(GNUTLS_VERSION)

gnutls-setup: setup
	$(call EXTRACT_TAR,gnutls-$(GNUTLS_VERSION).tar.xz,gnutls-$(GNUTLS_VERSION),gnutls)
	mkdir -p $(BUILD_WORK)/gnutls/lib/accelerated/aarch64/macosx
	wget -q -nc -P $(BUILD_WORK)/gnutls/lib/accelerated/aarch64/macosx \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/aes-aarch64.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/ghash-aarch64.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha1-armv8.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha256-armv8.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha512-armv8.s
	$(SED) -i '/-Wl,-no_weak_imports/d' $(BUILD_WORK)/gnutls/configure.ac # Workaround for XCode 11.4 bug, remove this when Apple fixes.

ifneq ($(wildcard $(BUILD_WORK)/gnutls/.build_complete),)
gnutls:
	@echo "Using previously built gnutls."
else
gnutls: gnutls-setup readline gettext libgcrypt libgmp10 libidn2 libunistring nettle p11-kit
	find $(BUILD_BASE) -name "*.la" -type f -delete
	if ! [ -f $(BUILD_WORK)/gnutls/configure ]; then \
		cd $(BUILD_WORK)/gnutls && autoreconf -f -i ; \
	fi
	cd $(BUILD_WORK)/gnutls && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		P11_KIT_CFLAGS=-I$(BUILD_BASE)/usr/include/p11-kit-1
	+$(MAKE) -C $(BUILD_WORK)/gnutls
	+$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_STAGE)/gnutls
	+$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_BASE)
	rm -rf $(BUILD_STAGE)/gnutls/usr/share
	touch $(BUILD_WORK)/gnutls/.build_complete
endif

gnutls-package: gnutls-stage
	# gnutls.mk Package Structure
	rm -rf $(BUILD_DIST)/gnutls
	mkdir -p $(BUILD_DIST)/gnutls
	
	# gnutls.mk Prep gnutls
	cp -a $(BUILD_STAGE)/gnutls/usr $(BUILD_DIST)/gnutls
	
	# gnutls.mk Sign
	$(call SIGN,gnutls,general.xml)
	
	# gnutls.mk Make .debs
	$(call PACK,gnutls,DEB_GNUTLS_V)
	
	# gnutls.mk Build cleanup
	rm -rf $(BUILD_DIST)/gnutls

.PHONY: gnutls gnutls-package
