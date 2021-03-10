ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += futurerestore
FUTURERESTORE_VERSION := 195
DEB_FUTURERESTORE_V   ?= $(FUTURERESTORE_VERSION)

FUTURERESTORE_COMMIT  := 55db758b5d4d6c08daa48af9aad1abf2b6466f36
IDEVICERESTORE_COMMIT := d7d9996b3910902a56462fa8d9dc5909fcf8f4c9

futurerestore-setup: setup tsschecker-setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/marijuanARM/futurerestore/archive/$(FUTURERESTORE_COMMIT).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/marijuanARM/idevicerestore/archive/$(IDEVICERESTORE_COMMIT).tar.gz
	$(call EXTRACT_TAR,$(FUTURERESTORE_COMMIT).tar.gz,futurerestore-$(FUTURERESTORE_COMMIT),futurerestore)
	
	-$(RMDIR) $(BUILD_WORK)/futurerestore/external/{idevicerestore,tsschecker}
	$(call EXTRACT_TAR,$(IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(IDEVICERESTORE_COMMIT),futurerestore/external/idevicerestore)
	cp -R $(BUILD_WORK)/tsschecker $(BUILD_WORK)/futurerestore/external

ifneq ($(wildcard $(BUILD_WORK)/futurerestore/.build_complete),)
futurerestore:
	@echo "Using previously built futurerestore."
else
futurerestore: futurerestore-setup libirecovery openssl libusbmuxd libimobiledevice img4tool libgeneral libipatcher libzip
	cd $(BUILD_WORK)/futurerestore && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/futurerestore
	+$(MAKE) -C $(BUILD_WORK)/futurerestore install \
		DESTDIR="$(BUILD_STAGE)/futurerestore"
	touch $(BUILD_WORK)/futurerestore/.build_complete
endif

futurerestore-package: futurerestore-stage
	# futurerestore.mk Package Structure
	rm -rf $(BUILD_DIST)/futurerestore
	mkdir -p $(BUILD_DIST)/futurerestore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# futurerestore.mk Prep futurerestore
	cp -a $(BUILD_STAGE)/futurerestore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/futurerestore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# futurerestore.mk Sign
	$(call SIGN,futurerestore,general.xml)
	
	# futurerestore.mk Make .debs
	$(call PACK,futurerestore,DEB_FUTURERESTORE_V)
	
	# futurerestore.mk Build cleanup
	rm -rf $(BUILD_DIST)/futurerestore

.PHONY: futurerestore futurerestore-package
