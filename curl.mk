ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

CURL_VERSION := 7.69.1
DEB_CURL_V   ?= $(CURL_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/curl/.build_complete),)
curl:
	@echo "Using previously built curl."
else
curl: setup libressl libssh2 nghttp2
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
	$(FAKEROOT) cp -a $(BUILD_STAGE)/curl/usr $(BUILD_DIST)/curl
	
	# curl.mk Sign
	$(call SIGN,curl,general.xml)
	
	# curl.mk Make .debs
	$(call PACK,curl,DEB_CURL_V)
	
	# curl.mk Build cleanup
	rm -rf $(BUILD_DIST)/curl

.PHONY: curl curl-package
