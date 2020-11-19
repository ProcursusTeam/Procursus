ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += cacerts
CACERTS_VERSION := 0.0.3
DEB_CACERTS_V   ?= $(CACERTS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/cacerts/.build_complete),)
cacerts:
	@echo "Using previously built cacerts."
else
cacerts: setup curl-setup
	mkdir -p $(BUILD_WORK)/cacerts
	cd $(BUILD_WORK)/cacerts && $(BUILD_WORK)/curl/lib/mk-ca-bundle.pl
	echo -e "## git ##\ngit config --global http.sslCAInfo /etc/ssl/certs/cacert.pem &> /dev/null" > $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh
	mkdir -p $(BUILD_STAGE)/cacerts/etc/{profile.d,ssl/certs}
	cp $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh $(BUILD_STAGE)/cacerts/etc/profile.d
	cp $(BUILD_WORK)/cacerts/ca-bundle.crt $(BUILD_STAGE)/cacerts/etc/ssl/certs/cacert.pem
	ln -s certs/cacert.pem $(BUILD_STAGE)/cacerts/etc/ssl/cert.pem
	touch $(BUILD_WORK)/cacerts/.build_complete
endif

cacerts-package: cacerts-stage
	# cacerts.mk Package Structure
	rm -rf $(BUILD_DIST)/ca-certificates
	mkdir -p $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl
	
	# cacerts.mk Prep ca-certificates
	cp -a $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)
	ln -s /$(MEMO_PREFIX)/etc/ssl/certs $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl
	ln -s /$(MEMO_PREFIX)/etc/ssl/certs/cacert.pem $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl

	# cacerts.mk Permissions
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/ca-certificates/etc/profile.d/cacerts.bootstrap.sh
	
	# cacerts.mk Make .debs
	$(call PACK,ca-certificates,DEB_CACERTS_V)
	
	# cacerts.mk Build cleanup
	rm -rf $(BUILD_DIST)/ca-certificates

.PHONY: cacerts cacerts-package
