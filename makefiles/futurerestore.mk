ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                         += futurerestore
FUTURERESTORE_VERSION               := 290
FUTURERESTORE_COMMIT                := 7f732140187bbcecfed3c34ac38185a4096d06d7
FUTURERESTORE_IDEVICERESTORE_COMMIT := b46637056fce7cb771f53916b1a8c527d256c5f2
DEB_FUTURERESTORE_V                 ?= $(FUTURERESTORE_VERSION)

futurerestore-setup: setup tsschecker-setup
	$(call GITHUB_ARCHIVE,futurerestore,futurerestore,$(FUTURERESTORE_COMMIT),$(FUTURERESTORE_COMMIT))
	$(call GITHUB_ARCHIVE,futurerestore,idevicerestore,$(FUTURERESTORE_IDEVICERESTORE_COMMIT),$(FUTURERESTORE_IDEVICERESTORE_COMMIT))
	$(call EXTRACT_TAR,futurerestore-$(FUTURERESTORE_COMMIT).tar.gz,futurerestore-$(FUTURERESTORE_COMMIT),futurerestore)
	-rmdir $(BUILD_WORK)/futurerestore/external/{idevicerestore,tsschecker}
	$(call EXTRACT_TAR,idevicerestore-$(FUTURERESTORE_IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(FUTURERESTORE_IDEVICERESTORE_COMMIT),futurerestore/external/idevicerestore)
	cp -RpP $(BUILD_WORK)/tsschecker $(BUILD_WORK)/futurerestore/external


ifneq ($(wildcard $(BUILD_WORK)/futurerestore/.build_complete),)
futurerestore:
	@echo "Using previously built futurerestore."
else
futurerestore: futurerestore-setup libirecovery openssl libusbmuxd libimobiledevice img4tool libgeneral libzip libfragmentzip libipatcher
	cd $(BUILD_WORK)/futurerestore && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DARCH="$(MEMO_ARCH)" \
		-DVERSION_COMMIT_COUNT="$(FUTURERESTORE_VERSION)" \
		-DVERSION_COMMIT_SHA="$(FUTURERESTORE_COMMIT)" \
		-DCMAKE_INSTALL_RPATH="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
		-DNO_XCODE=1
	+$(MAKE) -C $(BUILD_WORK)/futurerestore
	+$(MAKE) -C $(BUILD_WORK)/futurerestore install \
		DESTDIR="$(BUILD_STAGE)/futurerestore"
	$(call AFTER_BUILD)
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
