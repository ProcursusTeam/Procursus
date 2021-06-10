ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += idevicerestore
IDEVICERESTORE_COMMIT  := a2010182daa49f9f3bb63e8993908f8cdbca8b5e
IDEVICERESTORE_VERSION := 1.0.0+git20210526.$(shell echo $(IDEVICERESTORE_COMMIT) | cut -c -7)
DEB_IDEVICERESTORE_V   ?= $(IDEVICERESTORE_VERSION)

idevicerestore-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,idevicerestore,$(IDEVICERESTORE_COMMIT),$(IDEVICERESTORE_COMMIT))
	$(call EXTRACT_TAR,idevicerestore-$(IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(IDEVICERESTORE_COMMIT),idevicerestore)

ifneq ($(wildcard $(BUILD_WORK)/idevicerestore/.build_complete),)
idevicerestore:
	@echo "Using previously built idevicerestore."
else
idevicerestore: idevicerestore-setup curl libimobiledevice libirecovery libplist libzip
	cd $(BUILD_WORK)/idevicerestore && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		zlib_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lz" \
		zlib_CFLAGS="-I$(TARGET_SYSROOT)/usr/include"
	+$(MAKE) -C $(BUILD_WORK)/idevicerestore
	+$(MAKE) -C $(BUILD_WORK)/idevicerestore install \
		DESTDIR="$(BUILD_STAGE)/idevicerestore"
	touch $(BUILD_WORK)/idevicerestore/.build_complete
endif

idevicerestore-package: idevicerestore-stage
	# idevicerestore.mk Package Structure
	rm -rf $(BUILD_DIST)/idevicerestore

	# idevicerestore.mk Prep idevicerestore
	cp -a $(BUILD_STAGE)/idevicerestore $(BUILD_DIST)

	# idevicerestore.mk Sign
	$(call SIGN,idevicerestore,general.xml)

	# idevicerestore.mk Make .debs
	$(call PACK,idevicerestore,DEB_IDEVICERESTORE_V)

	# idevicerestore.mk Build cleanup
	rm -rf $(BUILD_DIST)/idevicerestore

.PHONY: idevicerestore idevicerestore-package
