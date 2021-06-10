ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += cacerts

ifneq ($(wildcard $(BUILD_WORK)/cacerts/.build_complete),)
cacerts:
	@echo "Using previously built cacerts."
else
cacerts: setup curl-setup
	mkdir -p $(BUILD_WORK)/cacerts
	cd $(BUILD_WORK)/cacerts && $(BUILD_WORK)/curl/lib/mk-ca-bundle.pl
	echo -e "## git ##\ngit config --global http.sslCAInfo $(MEMO_PREFIX)/etc/ssl/certs/cacert.pem >/dev/null 2>&1" > $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh
	mkdir -p $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc/{profile.d,ssl/certs}
	cp $(BUILD_WORK)/cacerts/cacerts.bootstrap.sh $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_WORK)/cacerts/ca-bundle.crt $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc/ssl/certs/cacert.pem
	ln -s certs/cacert.pem $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc/ssl/cert.pem
	touch $(BUILD_WORK)/cacerts/.build_complete
endif

cacerts-package: cacerts-stage
	# Set version info
	$(eval DEB_CACERTS_V := $(shell PATH="$(PATH)" date --date="$(shell PATH="$(PATH)" egrep -Eo '([a-zA-Z]+( [a-zA-Z]+)+)\s+(0?[1-9]|[12][0-9]|3[01])\s+[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,3})?\s+[0-9]+\s+[a-zA-Z]+' $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc/ssl/certs/cacert.pem)" +"%+4Y%m%d"))

	# cacerts.mk Package Structure
	rm -rf $(BUILD_DIST)/ca-certificates
	mkdir -p $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl

	# cacerts.mk Prep ca-certificates
	cp -a $(BUILD_STAGE)/cacerts/$(MEMO_PREFIX)/etc $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)
	ln -s $(MEMO_PREFIX)/etc/ssl/certs $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl
	ln -s $(MEMO_PREFIX)/etc/ssl/certs/cacert.pem $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ssl

	# cacerts.mk Permissions
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/ca-certificates/$(MEMO_PREFIX)/etc/profile.d/cacerts.bootstrap.sh

	# cacerts.mk Make .debs
	$(call PACK,ca-certificates,DEB_CACERTS_V)

	# cacerts.mk Build cleanup
	rm -rf $(BUILD_DIST)/ca-certificates

.PHONY: cacerts cacerts-package
