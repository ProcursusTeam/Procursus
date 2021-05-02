ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += aria2
ARIA2_VERSION := 1.35.0
DEB_ARIA2_V   ?= $(ARIA2_VERSION)

aria2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tatsuhiro-t/aria2/releases/download/release-$(ARIA2_VERSION)/aria2-$(ARIA2_VERSION).tar.xz
	$(call EXTRACT_TAR,aria2-$(ARIA2_VERSION).tar.xz,aria2-$(ARIA2_VERSION),aria2)

ifneq ($(wildcard $(BUILD_WORK)/aria2/.build_complete),)
aria2:
	@echo "Using previously built aria2."
else
aria2: aria2-setup openssl libjemalloc libuv1 libssh2 libc-ares
	cd $(BUILD_WORK)/aria2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--enable-libaria2 \
		--with-openssl \
		--without-gnutls \
		--without-libgcrypt \
		--without-appletls \
		--with-libcares \
		--with-jemalloc \
		--with-libssh2 \
		--with-libuv \
		--with-ca-bundle=$(MEMO_PREFIX)/etc/ssl/certs/cacert.pem
	+$(MAKE) -C $(BUILD_WORK)/aria2
	+$(MAKE) -C $(BUILD_WORK)/aria2 install \
		DESTDIR=$(BUILD_STAGE)/aria2
	touch $(BUILD_WORK)/aria2/.build_complete
endif

aria2-package: aria2-stage
	# aria2.mk Package Structure
	rm -rf $(BUILD_DIST)/aria2 \
		$(BUILD_DIST)/libaria2-0{,-dev}
	mkdir -p $(BUILD_DIST)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libaria2-0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# aria2.mk Prep aria2
	cp -a $(BUILD_STAGE)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# aria2.mk Prep libaria2-0
	cp -a $(BUILD_STAGE)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaria2.0.dylib $(BUILD_DIST)/libaria2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# aria2.mk Prep libaria2-0-dev
	cp -a $(BUILD_STAGE)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libaria2.dylib,pkgconfig} $(BUILD_DIST)/libaria2-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/aria2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libaria2-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# aria2.mk Sign
	$(call SIGN,aria2,general.xml)
	$(call SIGN,libaria2-0,general.xml)

	# aria2.mk Make .debs
	$(call PACK,aria2,DEB_ARIA2_V)
	$(call PACK,libaria2-0,DEB_ARIA2_V)
	$(call PACK,libaria2-0-dev,DEB_ARIA2_V)

	# aria2.mk Build cleanup
	rm -rf $(BUILD_DIST)/aria2 \
		$(BUILD_DIST)/libaria2-0{,-dev}

.PHONY: aria2 aria2-package
