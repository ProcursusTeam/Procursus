ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += curl
CURL_VERSION := 7.74.0
DEB_CURL_V   ?= $(CURL_VERSION)

curl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://curl.haxx.se/download/curl-$(CURL_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,curl-$(CURL_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,curl-$(CURL_VERSION).tar.xz,curl-$(CURL_VERSION),curl)

ifneq ($(wildcard $(BUILD_WORK)/curl/.build_complete),)
curl:
	@echo "Using previously built curl."
else
curl: curl-setup gettext openssl libssh2 nghttp2 libidn2 brotli zstd rtmpdump
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
	rm -rf $(BUILD_DIST)/curl \
		$(BUILD_DIST)/libcurl4{,-openssl-dev}
	mkdir -p $(BUILD_DIST)/curl/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/libcurl4-openssl-dev/usr/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/libcurl4/usr/lib
	
	# curl.mk Prep curl
	cp -a $(BUILD_STAGE)/curl/usr/bin/curl $(BUILD_DIST)/curl/usr/bin
	cp -a $(BUILD_STAGE)/curl/usr/share/man/man1/curl.1 $(BUILD_DIST)/curl/usr/share/man/man1
	
	# curl.mk Prep libcurl4
	cp -a $(BUILD_STAGE)/curl/usr/lib/libcurl.4.dylib $(BUILD_DIST)/libcurl4/usr/lib
	
	# curl.mk Prep libcurl4-openssl-dev
	cp -a $(BUILD_STAGE)/curl/usr/lib/{pkgconfig,libcurl.{dylib,a}} $(BUILD_DIST)/libcurl4-openssl-dev/usr/lib
	cp -a $(BUILD_STAGE)/curl/usr/share/man/man1/curl-config.1 $(BUILD_DIST)/libcurl4-openssl-dev/usr/share/man/man1
	cp -a $(BUILD_STAGE)/curl/usr/share/man/man3 $(BUILD_DIST)/libcurl4-openssl-dev/usr/share/man
	cp -a $(BUILD_STAGE)/curl/usr/bin/curl-config $(BUILD_DIST)/libcurl4-openssl-dev/usr/bin
	cp -a $(BUILD_STAGE)/curl/usr/include $(BUILD_DIST)/libcurl4-openssl-dev/usr
	
	# curl.mk Sign
	$(call SIGN,curl,general.xml)
	$(call SIGN,libcurl4,general.xml)
	$(call SIGN,libcurl4-openssl-dev,general.xml)
	
	# curl.mk Make .debs
	$(call PACK,curl,DEB_CURL_V)
	$(call PACK,libcurl4,DEB_CURL_V)
	$(call PACK,libcurl4-openssl-dev,DEB_CURL_V)
	
	# curl.mk Build cleanup
	rm -rf $(BUILD_DIST)/curl \
		$(BUILD_DIST)/libcurl4{,-openssl-dev}

.PHONY: curl curl-package
