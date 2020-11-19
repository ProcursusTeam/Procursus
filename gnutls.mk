ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += gnutls
GNUTLS_VERSION := 3.6.15
DEB_GNUTLS_V   ?= $(GNUTLS_VERSION)-1

gnutls-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-$(GNUTLS_VERSION).tar.xz
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
	cd $(BUILD_WORK)/gnutls && autoreconf -f -i
ifeq ($(MEMO_TARGET),watchos-arm64)
	cd $(BUILD_WORK)/gnutls && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-hardware-acceleration \
 		P11_KIT_CFLAGS=-I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/p11-kit-1
else
	cd $(BUILD_WORK)/gnutls && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		P11_KIT_CFLAGS=-I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/p11-kit-1
endif
	+$(MAKE) -C $(BUILD_WORK)/gnutls
	+$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_STAGE)/gnutls
	+$(MAKE) -C $(BUILD_WORK)/gnutls install \
		DESTDIR=$(BUILD_BASE)
	rm -rf $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	touch $(BUILD_WORK)/gnutls/.build_complete
endif

gnutls-package: gnutls-stage
	# gnutls.mk Package Structure
	rm -rf $(BUILD_DIST)/gnutls-bin \
		$(BUILD_DIST)/libgnutls30 \
		$(BUILD_DIST)/libgnutlsxx28 \
		$(BUILD_DIST)/libgnutls28-dev
	mkdir -p $(BUILD_DIST)/gnutls-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libgnutls30/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgnutlsxx28/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgnutls28-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# gnutls.mk Prep gnutls-bin
	cp -a $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/gnutls-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# gnutls.mk Prep libgnutls30
	cp -a $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgnutls.30.dylib $(BUILD_DIST)/libgnutls30/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# gnutls.mk Prep libgnutlsxx28
	cp -a $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgnutlsxx.28.dylib $(BUILD_DIST)/libgnutlsxx28/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# gnutls.mk Prep libgnutls28-dev
	cp -a $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libgnutls{,xx}.dylib} $(BUILD_DIST)/libgnutls28-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gnutls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgnutls28-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# gnutls.mk Sign
	$(call SIGN,gnutls-bin,general.xml)
	$(call SIGN,libgnutls30,general.xml)
	$(call SIGN,libgnutlsxx28,general.xml)
	
	# gnutls.mk Make .debs
	$(call PACK,gnutls-bin,DEB_GNUTLS_V)
	$(call PACK,libgnutls30,DEB_GNUTLS_V)
	$(call PACK,libgnutlsxx28,DEB_GNUTLS_V)
	$(call PACK,libgnutls28-dev,DEB_GNUTLS_V)
	
	# gnutls.mk Build cleanup
	rm -rf $(BUILD_DIST)/gnutls-bin \
		$(BUILD_DIST)/libgnutls30 \
		$(BUILD_DIST)/libgnutlsxx28 \
		$(BUILD_DIST)/libgnutls28-dev

.PHONY: gnutls gnutls-package
