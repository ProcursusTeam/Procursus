ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += curl
CURL_VERSION := 7.71.0
DEB_CURL_V   ?= $(CURL_VERSION)

curl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://curl.haxx.se/download/curl-$(CURL_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,curl-$(CURL_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,curl-$(CURL_VERSION).tar.xz,curl-$(CURL_VERSION),curl)

ifneq ($(wildcard $(BUILD_WORK)/curl/.build_complete),)
curl:
	@echo "Using previously built curl."
else
curl: curl-setup openssl libssh2 nghttp2 libidn2 libunistring
	cd $(BUILD_WORK)/curl && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--disable-dependency-tracking \
		--with-libssh2 \
		--with-nghttp2 \
		--with-ca-bundle=/etc/ssl/certs/cacert.pem
	+$(MAKE) -C $(BUILD_WORK)/curl
	+$(MAKE) -C $(BUILD_WORK)/curl install \
		DESTDIR="$(BUILD_STAGE)/curl"
	+$(MAKE) -C $(BUILD_WORK)/curl install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/curl/.build_complete
endif

curl-package: curl-stage
	# curl.mk Package Structure
	rm -rf $(BUILD_DIST)/curl
	mkdir -p $(BUILD_DIST)/curl
	
	# curl.mk Prep curl
	cp -a $(BUILD_STAGE)/curl/usr $(BUILD_DIST)/curl
	
	# curl.mk Sign
	$(call SIGN,curl,general.xml)
	
	# curl.mk Make .debs
	$(call PACK,curl,DEB_CURL_V)
	
	# curl.mk Build cleanup
	rm -rf $(BUILD_DIST)/curl

.PHONY: curl curl-package
