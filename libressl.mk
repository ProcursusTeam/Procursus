ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS      += libressl
LIBRESSL_VERSION := 3.3.1
DEB_LIBRESSL_V   ?= $(LIBRESSL_VERSION)

libressl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-$(LIBRESSL_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,libressl-$(LIBRESSL_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,libressl-$(LIBRESSL_VERSION).tar.gz,libressl-$(LIBRESSL_VERSION),libressl)

ifneq ($(wildcard $(BUILD_WORK)/libressl/.build_complete),)
libressl:
	@echo "Using previously built libressl."
else
libressl: libressl-setup
	cd $(BUILD_WORK)/libressl && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-openssldir=$(MEMO_PREFIX)/etc/ssl
	+$(MAKE) -C $(BUILD_WORK)/libressl
	+$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_STAGE)/libressl
	+$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libressl/.build_complete
endif

libressl-package: libressl-stage
	# libressl.mk Package Structure
	rm -rf $(BUILD_DIST)/libressl
	mkdir -p $(BUILD_DIST)/libressl

	# libressl.mk Prep libressl
	cp -a $(BUILD_STAGE)/libressl/$(MEMO_PREFIX) $(BUILD_DIST)/libressl

	# libressl.mk Sign
	$(call SIGN,libressl,general.xml)

	# libressl.mk Make .debs
	$(call PACK,libressl,DEB_LIBRESSL_V)

	# libressl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libressl

.PHONY: libressl libressl-package
