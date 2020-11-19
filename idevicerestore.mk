ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += idevicerestore
IDEVICERESTORE_VERSION := 1.0.0
DEB_IDEVICERESTORE_V   ?= $(IDEVICERESTORE_VERSION)-1

idevicerestore-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/idevicerestore/releases/download/$(IDEVICERESTORE_VERSION)/idevicerestore-$(IDEVICERESTORE_VERSION).tar.bz2
	$(call EXTRACT_TAR,idevicerestore-$(IDEVICERESTORE_VERSION).tar.bz2,idevicerestore-$(IDEVICERESTORE_VERSION),idevicerestore)

ifneq ($(wildcard $(BUILD_WORK)/idevicerestore/.build_complete),)
idevicerestore:
	@echo "Using previously built idevicerestore."
else
idevicerestore: idevicerestore-setup curl libimobiledevice libirecovery libplist libzip
	cd $(BUILD_WORK)/idevicerestore && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
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
