ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

GNUTLS_VERSION := 3.6.12
DEB_GNUTLS_V   ?= $(GNUTLS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/gnutls/.build_complete),)
gnutls:
	@echo "Using previously built gnutls."
else
gnutls: setup readline gettext libgcrypt libgmp10 libidn2 libunistring nettle p11-kit
	find $(BUILD_BASE) -name "*.la" -type f -delete
	if ! [ -f $(BUILD_WORK)/gnutls/configure ]; then \
		cd $(BUILD_WORK)/gnutls && autoreconf -f -i ; \
	fi
	mkdir -p $(BUILD_WORK)/gnutls/lib/accelerated/aarch64/macosx
	wget -nc -P $(BUILD_WORK)/gnutls/lib/accelerated/aarch64/macosx \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/aes-aarch64.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/ghash-aarch64.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha1-armv8.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha256-armv8.s \
		https://gitlab.com/gnutls/gnutls/-/raw/master/lib/accelerated/aarch64/macosx/sha512-armv8.s
	cd $(BUILD_WORK)/gnutls && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		P11_KIT_CFLAGS=-I$(BUILD_BASE)/usr/include/p11-kit-1
	$(MAKE) -C $(BUILD_WORK)/gnutls
	$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_STAGE)/gnutls
	$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gnutls/.build_complete
endif

.PHONY: gnutls
