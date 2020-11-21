ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += futurerestore
FUTURERESTORE_VERSION := 180
DEB_FUTURERESTORE_V   ?= $(FUTURERESTORE_VERSION)-1

IDEVICERESTORE_COMMIT := 12667e70defe51fec607ff3006729d0cb5a6aaa8

futurerestore-setup: setup tsschecker-setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/futurerestore/archive/$(FUTURERESTORE_VERSION).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/marijuanARM/idevicerestore/archive/$(IDEVICERESTORE_COMMIT).tar.gz
	$(call EXTRACT_TAR,$(FUTURERESTORE_VERSION).tar.gz,futurerestore-$(FUTURERESTORE_VERSION),futurerestore)
	
	-$(RMDIR) $(BUILD_WORK)/futurerestore/external/{idevicerestore,tsschecker}
	$(call EXTRACT_TAR,$(IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(IDEVICERESTORE_COMMIT),futurerestore/external/idevicerestore)
	cp -R $(BUILD_WORK)/tsschecker $(BUILD_WORK)/futurerestore/external

	$(SED) -i 's/libplist /libplist-2.0 /g' $(BUILD_WORK)/futurerestore/configure.ac
	$(SED) -i 's/libirecovery /libirecovery-1.0 /g' $(BUILD_WORK)/futurerestore/configure.ac
	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/futurerestore/configure.ac
	$(SED) -i '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/futurerestore/configure.ac

	$(SED) -i 's/libplist /libplist-2.0 /g' $(BUILD_WORK)/futurerestore/external/idevicerestore/configure.ac
	$(SED) -i 's/libirecovery /libirecovery-1.0 /g' $(BUILD_WORK)/futurerestore/external/idevicerestore/configure.ac
	$(SED) -i 's/LIBPLIST_VERSION=1.12/LIBPLIST_VERSION=2.2.0/' $(BUILD_WORK)/futurerestore/external/idevicerestore/configure.ac
	$(SED) -i 's/LIBIRECOVERY_VERSION=0.2.0/LIBIRECOVERY_VERSION=1.0.0/' $(BUILD_WORK)/futurerestore/external/idevicerestore/configure.ac

	$(SED) -i 's/libipatcher::version().c_str()/libipatcher::version()/' $(BUILD_WORK)/futurerestore/futurerestore/main.cpp

ifneq ($(wildcard $(BUILD_WORK)/futurerestore/.build_complete),)
futurerestore:
	@echo "Using previously built futurerestore."
else
futurerestore: futurerestore-setup tsschecker libirecovery openssl libusbmuxd libimobiledevice img4tool libgeneral libipatcher libzip
	cd $(BUILD_WORK)/futurerestore && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/futurerestore
	+$(MAKE) -C $(BUILD_WORK)/futurerestore install \
		DESTDIR="$(BUILD_STAGE)/futurerestore"
	rm -f $(BUILD_STAGE)/futurerestore/usr/share/man/man1/idevicerestore.1
	touch $(BUILD_WORK)/futurerestore/.build_complete
endif

futurerestore-package: futurerestore-stage
	# futurerestore.mk Package Structure
	rm -rf $(BUILD_DIST)/futurerestore
	mkdir -p $(BUILD_DIST)/futurerestore/usr
	
	# futurerestore.mk Prep futurerestore
	cp -a $(BUILD_STAGE)/futurerestore/usr/{bin,share} $(BUILD_DIST)/futurerestore/usr
	
	# futurerestore.mk Sign
	$(call SIGN,futurerestore,general.xml)
	
	# futurerestore.mk Make .debs
	$(call PACK,futurerestore,DEB_FUTURERESTORE_V)
	
	# futurerestore.mk Build cleanup
	rm -rf $(BUILD_DIST)/futurerestore

.PHONY: futurerestore futurerestore-package
