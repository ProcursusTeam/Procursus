ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += ngtcp2
NGTCP2_VERSION := 0.9.0
DEB_NGTCP2_V   ?= $(NGTCP2_VERSION)

ngtcp2-setup: setup
	$(call GITHUB_ARCHIVE,ngtcp2,ngtcp2,$(NGTCP2_VERSION),v$(NGTCP2_VERSION))
	$(call EXTRACT_TAR,ngtcp2-$(NGTCP2_VERSION).tar.gz,ngtcp2-$(NGTCP2_VERSION),ngtcp2)
	sed -i '1i #define\ __APPLE_USE_RFC_3542\ 1' $(BUILD_WORK)/ngtcp2/examples/shared.cc
	sed -i '1i #define\ __APPLE_USE_RFC_3542\ 1' $(BUILD_WORK)/ngtcp2/examples/server.cc

ifneq ($(wildcard $(BUILD_WORK)/ngtcp2/.build_complete),)
ngtcp2:
	@echo "Using previously built ngtcp2."
else
ngtcp2: ngtcp2-setup gnutls nghttp3 libev
	cd $(BUILD_WORK)/ngtcp2 && autoreconf -fi
	cd $(BUILD_WORK)/ngtcp2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gnutls \
		--with-libnghttp3 \
		--with-libev \
		--without-jemalloc
	+$(MAKE) -C $(BUILD_WORK)/ngtcp2
	+$(MAKE) -C $(BUILD_WORK)/ngtcp2 install \
		DESTDIR="$(BUILD_STAGE)/ngtcp2"
	mkdir -p $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{,s}bin
	cp $(BUILD_WORK)/ngtcp2/examples/.libs/gtlsserver $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp $(BUILD_WORK)/ngtcp2/examples/.libs/gtlsclient $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD,copy)
endif

ngtcp2-package: ngtcp2-stage
	# ngtcp2.mk Package Structure
	rm -rf $(BUILD_DIST)/libngtcp2-{crypto-gnutls2,3,{crypto-gnutls-,}dev} $(BUILD_DIST)/ngtcp2-{client,server}
	mkdir -p $(BUILD_DIST)/libngtcp2-{crypto-gnutls2,3,{crypto-gnutls-,}dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libngtcp2-{crypto-gnutls-,}dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/ngtcp2,lib/pkgconfig} \
		$(BUILD_DIST)/ngtcp2-{client,server}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ngtcp2.mk Prep libngtcp2-3
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2.3.dylib $(BUILD_DIST)/libngtcp2-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ngtcp2.mk Prep libngtcp2-crypto-gnutls2
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2_crypto_gnutls.2.dylib $(BUILD_DIST)/libngtcp2-crypto-gnutls2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ngtcp2.mk Prep libngtcp2-dev
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2.{dylib,a} $(BUILD_DIST)/libngtcp2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libngtcp2.pc $(BUILD_DIST)/libngtcp2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ngtcp2/{ngtcp2,version}.h $(BUILD_DIST)/libngtcp2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ngtcp2/

	# ngtcp2.mk Prep libngtcp2-crypto-gnutls-dev
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2_crypto_gnutls.{dylib,a} $(BUILD_DIST)/libngtcp2-crypto-gnutls-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ngtcp2/ngtcp2_crypto{,_gnutls}.h $(BUILD_DIST)/libngtcp2-crypto-gnutls-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ngtcp2/
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libngtcp2_crypto_gnutls.pc $(BUILD_DIST)/libngtcp2-crypto-gnutls-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/

	# ngtcp2.mk Prep ngtcp2-server
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/ngtcp2-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nghttp2.mk Prep ngtcp2-client
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/ngtcp2-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ngtcp2.mk Sign
	$(call SIGN,libngtcp2-3,general.xml)
	$(call SIGN,libngtcp2-crypto-gnutls2,general.xml)
	$(call SIGN,ngtcp2-client,general.xml)
	$(call SIGN,ngtcp2-server,general.xml)

	# ngtcp2.mk Make .debs
	$(call PACK,libngtcp2-3,DEB_NGTCP2_V)
	$(call PACK,libngtcp2-dev,DEB_NGTCP2_V)
	$(call PACK,libngtcp2-crypto-gnutls2,DEB_NGTCP2_V)
	$(call PACK,libngtcp2-crypto-gnutls-dev,DEB_NGTCP2_V)
	$(call PACK,ngtcp2-client,DEB_NGTCP2_V)
	$(call PACK,ngtcp2-server,DEB_NGTCP2_V)

	# ngtcp2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libngtcp2-{crypto-gnutls2,3,{crypto-gnutls-,}dev} $(BUILD_DIST)/ngtcp2-{client,server}

.PHONY: ngtcp2 ngtcp2-package
