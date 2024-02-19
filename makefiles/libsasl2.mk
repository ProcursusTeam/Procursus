ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libsasl2
LIBSASL2_VERSION := 2.1.28
DEB_LIBSASL2_V   ?= $(LIBSASL2_VERSION)

libsasl2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-$(LIBSASL2_VERSION)/cyrus-sasl-$(LIBSASL2_VERSION).tar.gz
	$(call EXTRACT_TAR,cyrus-sasl-$(LIBSASL2_VERSION).tar.gz,cyrus-sasl-$(LIBSASL2_VERSION),libsasl2)

ifneq ($(wildcard $(BUILD_WORK)/libsasl2/.build_complete),)
libsasl2:
	@echo "Using previously built libsasl2."
else
libsasl2: libsasl2-setup openssl
	cd $(BUILD_WORK)/libsasl2 && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-gssapi \
		--disable-macos-framework \
		--enable-gss_mutexes \
		--enable-login \
		--enable-ntlm \
		--with-openssl=$(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		sasl_cv_dlsym_adds_uscore=no
	+$(MAKE) -C $(BUILD_WORK)/libsasl2 install install-data \
		DESTDIR="$(BUILD_STAGE)/libsasl2"
	$(call AFTER_BUILD)
endif

libsasl2-package: libsasl2-stage
	# libsasl2.mk Package Structure
	rm -rf $(BUILD_DIST)/libsasl2{,-dev,-modules{,-db,-otp}}
	mkdir -p $(BUILD_DIST)/libsasl2{,-dev,-modules{,-db,-otp}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/sasl2,share/man}

	# libsasl2.mk Prep libsasl2
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsasl2{,.3}.dylib $(BUILD_DIST)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsasl2.mk Prep libsasl2-dev
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsasl2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libsasl2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libsasl2.mk Prep libsasl2-modules
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2/lib{anonymous,crammd5,digestmd5,login,ntlm,plain}{,.3}.so $(BUILD_DIST)/libsasl2-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2

	# libsasl2.mk Prep libsasl2-modules-db
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2/libsasldb{,.3}.so $(BUILD_DIST)/libsasl2-modules-db/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2

	# libsasl2.mk Prep libsasl2-modules-otp
	cp -a $(BUILD_STAGE)/libsasl2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2/libotp{,.3}.so $(BUILD_DIST)/libsasl2-modules-otp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sasl2

	# libsasl2.mk Sign
	$(call SIGN,libsasl2,general.xml)
	$(call SIGN,libsasl2-modules,general.xml)
	$(call SIGN,libsasl2-modules-db,general.xml)
	$(call SIGN,libsasl2-modules-otp,general.xml)

	# libsasl2.mk Make .debs
	$(call PACK,libsasl2,DEB_LIBSASL2_V)
	$(call PACK,libsasl2-dev,DEB_LIBSASL2_V)
	$(call PACK,libsasl2-modules,DEB_LIBSASL2_V)
	$(call PACK,libsasl2-modules-db,DEB_LIBSASL2_V)
	$(call PACK,libsasl2-modules-otp,DEB_LIBSASL2_V)

	# libsasl2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsasl2{,-dev,-modules{,-db,-otp}}

.PHONY: libsasl2 libsasl2-package
