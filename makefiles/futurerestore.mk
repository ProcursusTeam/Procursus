ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                         += futurerestore
FUTURERESTORE_VERSION               := 195
FUTURERESTORE_COMMIT                := 55db758b5d4d6c08daa48af9aad1abf2b6466f36
FUTURERESTORE_IDEVICERESTORE_COMMIT := d7d9996b3910902a56462fa8d9dc5909fcf8f4c9
DEB_FUTURERESTORE_V                 ?= $(FUTURERESTORE_VERSION)-1

futurerestore-setup: setup tsschecker-setup
	$(call GITHUB_ARCHIVE,m1stadev,futurerestore,$(FUTURERESTORE_COMMIT),$(FUTURERESTORE_COMMIT))
	$(call GITHUB_ARCHIVE,m1stadev,idevicerestore,$(FUTURERESTORE_IDEVICERESTORE_COMMIT),$(FUTURERESTORE_IDEVICERESTORE_COMMIT))
	$(call EXTRACT_TAR,futurerestore-$(FUTURERESTORE_COMMIT).tar.gz,futurerestore-$(FUTURERESTORE_COMMIT),futurerestore)

	-rmdir $(BUILD_WORK)/futurerestore/external/{idevicerestore,tsschecker}
	$(call EXTRACT_TAR,idevicerestore-$(FUTURERESTORE_IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(FUTURERESTORE_IDEVICERESTORE_COMMIT),futurerestore/external/idevicerestore)
	cp -R $(BUILD_WORK)/tsschecker $(BUILD_WORK)/futurerestore/external

	$(SED) -i 's/git rev\-list \-\-count HEAD/printf ${FUTURERESTORE_VERSION}/g' $(BUILD_WORK)/futurerestore/configure.ac
	$(SED) -i 's/git rev\-parse HEAD/printf ${FUTURERESTORE_COMMIT}/g' $(BUILD_WORK)/futurerestore/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/futurerestore/.build_complete),)
futurerestore:
	@echo "Using previously built futurerestore."
else
futurerestore: futurerestore-setup libirecovery openssl libusbmuxd libimobiledevice img4tool libgeneral libzip libfragmentzip libipatcher
	cd $(BUILD_WORK)/futurerestore && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-silent-rules \
		zlib_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lz" \
		zlib_CFLAGS="-I$(TARGET_SYSROOT)/usr/include"
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
