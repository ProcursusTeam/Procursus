ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

CACERTS_VERSION := 0.0.3
DEB_CACERTS_V   ?= $(CACERTS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/cacerts/.build_complete),)
cacerts:
	@echo "Using previously built cacerts."
else
cacerts: setup
	mkdir -p $(BUILD_WORK)/cacerts
	wget -nc -P $(BUILD_WORK)/cacerts \
		https://hg.mozilla.org/mozilla-central/raw-file/tip/security/nss/lib/ckfw/builtins/certdata.txt
	echo -e "## git ##\ngit config --global http.sslCAInfo /etc/ssl/certs/cacert.pem &> /dev/null" > $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh
	mkdir -p $(BUILD_STAGE)/cacerts/etc/{profile.d,ssl/certs}
	cp $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh $(BUILD_STAGE)/cacerts/etc/profile.d
	cp $(BUILD_WORK)/cacerts/certdata.txt $(BUILD_STAGE)/cacerts/etc/ssl/certs/cacert.pem
	touch $(BUILD_WORK)/cacerts/.build_complete
endif

cacerts-stage: cacerts
	# cacerts.mk Package Structure
	rm -rf $(BUILD_DIST)/ca-certificates
	mkdir -p $(BUILD_DIST)/ca-certificates/usr/lib/ssl
	
	# cacerts.mk Prep ca-certificates
	cp -a $(BUILD_STAGE)/cacerts/etc $(BUILD_DIST)/ca-certificates
	ln -s /etc/ssl/certs $(BUILD_DIST)/ca-certificates/usr/lib/ssl
	ln -s /etc/ssl/certs/cacert.pem $(BUILD_DIST)/ca-certificates/usr/lib/ssl
	
	# cacerts.mk Make .debs
	$(call PACK,ca-certificates,DEB_CACERTS_V)
	
	# cacerts.mk Build cleanup
	rm -rf $(BUILD_DIST)/ca-certificates

.PHONY: cacerts cacerts-stage
