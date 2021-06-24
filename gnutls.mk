ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += gnutls
GNUTLS_VERSION := 3.7.1
DEB_GNUTLS_V   ?= $(GNUTLS_VERSION)

gnutls-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.gnupg.org/ftp/gcrypt/gnutls/v$(shell echo $(GNUTLS_VERSION) | cut -d. -f-2)/gnutls-$(GNUTLS_VERSION).tar.xz
	$(call EXTRACT_TAR,gnutls-$(GNUTLS_VERSION).tar.xz,gnutls-$(GNUTLS_VERSION),gnutls)

ifneq ($(wildcard $(BUILD_WORK)/gnutls/.build_complete),)
gnutls:
	@echo "Using previously built gnutls."
else
gnutls: gnutls-setup readline gettext libgcrypt libgmp10 libidn2 libunistring nettle p11-kit
	find $(BUILD_BASE) -name "*.la" -type f -delete
	cd $(BUILD_WORK)/gnutls && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-guile \
		--enable-local-libopts \
		--with-default-trust-store-file=$(MEMO_PREFIX)/etc/ssl/certs/cacert.pem \
		P11_KIT_CFLAGS=-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/p11-kit-1
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
