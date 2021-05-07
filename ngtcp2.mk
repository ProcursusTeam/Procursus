ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += ngtcp2
NGTCP2_COMMIT  := f183441a41bd0067f17fc06df5ecc4ff6cefcc5c
NGTCP2_VERSION := 0~20210421.$(shell echo $(NGTCP2_COMMIT) | cut -c -7)
DEB_NGTCP2_V   ?= $(NGTCP2_VERSION)

ngtcp2-setup: setup
	$(call GITHUB_ARCHIVE,ngtcp2,ngtcp2,$(NGTCP2_COMMIT),$(NGTCP2_COMMIT))
	$(call EXTRACT_TAR,ngtcp2-$(NGTCP2_COMMIT).tar.gz,ngtcp2-$(NGTCP2_COMMIT),ngtcp2)

ifneq ($(wildcard $(BUILD_WORK)/ngtcp2/.build_complete),)
ngtcp2:
	@echo "Using previously built ngtcp2."
else
ngtcp2: ngtcp2-setup gnutls nghttp3 libjemalloc libev
	cd $(BUILD_WORK)/ngtcp2 && autoreconf -fi
	cd $(BUILD_WORK)/ngtcp2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gnutls \
		--with-libnghttp3 \
		--with-libev \
		--with-jemalloc
	+$(MAKE) -C $(BUILD_WORK)/ngtcp2
	+$(MAKE) -C $(BUILD_WORK)/ngtcp2 install \
		DESTDIR="$(BUILD_STAGE)/ngtcp2"
	+$(MAKE) -C $(BUILD_WORK)/ngtcp2 install \
		DESTDIR="$(BUILD_BASE)"
	mkdir -p $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{,s}bin
	cp $(BUILD_WORK)/ngtcp2/examples/.libs/gtlsserver $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp $(BUILD_WORK)/ngtcp2/examples/.libs/gtlsclient $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/ngtcp2/.build_complete
endif

ngtcp2-package: ngtcp2-stage
	# ngtcp2.mk Package Structure
	rm -rf $(BUILD_DIST)/libngtcp2-{crypto-gnutls0,0,dev} $(BUILD_DIST)/ngtcp2-{client,server}
	mkdir -p $(BUILD_DIST)/libngtcp2-{crypto-gnutls0,0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/ngtcp2-{client,server}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ngtcp2.mk Prep libngtcp2-0
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2.0.dylib $(BUILD_DIST)/libngtcp2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ngtcp2.mk Prep libngtcp2-crypto-gnutls0
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libngtcp2_crypto_gnutls.0.dylib $(BUILD_DIST)/libngtcp2-crypto-gnutls0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ngtcp2.mk Prep libngtcp2-dev
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libngtcp2*.0.dylib) $(BUILD_DIST)/libngtcp2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libngtcp2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nghttp2.mk Prep ngtcp2-server
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/ngtcp2-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nghttp2.mk Prep ngtcp2-client
	cp -a $(BUILD_STAGE)/ngtcp2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/ngtcp2-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ngtcp2.mk Sign
	$(call SIGN,libngtcp2-0,general.xml)
	$(call SIGN,libngtcp2-crypto-gnutls0,general.xml)
	$(call SIGN,ngtcp2-client,general.xml)
	$(call SIGN,ngtcp2-server,general.xml)

	# ngtcp2.mk Make .debs
	$(call PACK,libngtcp2-0,DEB_NGTCP2_V)
	$(call PACK,libngtcp2-dev,DEB_NGTCP2_V)
	$(call PACK,libngtcp2-crypto-gnutls0,DEB_NGTCP2_V)
	$(call PACK,ngtcp2-client,DEB_NGTCP2_V)
	$(call PACK,ngtcp2-server,DEB_NGTCP2_V)

	# ngtcp2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libngtcp2-{crypto-gnutls0,0,dev} $(BUILD_DIST)/ngtcp2-{client,server}

.PHONY: ngtcp2 ngtcp2-package
