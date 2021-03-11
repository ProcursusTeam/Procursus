ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += idevicerestore
IDEVICERESTORE_COMMIT  := 6d3b6bba9127c02fc312468e4174e8148bf87472
IDEVICERESTORE_VERSION := 1.0.0+git20210304.$(shell echo $(IDEVICERESTORE_COMMIT) | cut -c -7)
DEB_IDEVICERESTORE_V   ?= $(IDEVICERESTORE_VERSION)

idevicerestore-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/idevicerestore-$(IDEVICERESTORE_COMMIT).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/idevicerestore-$(IDEVICERESTORE_COMMIT).tar.gz \
			https://github.com/libimobiledevice/idevicerestore/archive/$(IDEVICERESTORE_COMMIT).tar.gz
	$(call EXTRACT_TAR,idevicerestore-$(IDEVICERESTORE_COMMIT).tar.gz,idevicerestore-$(IDEVICERESTORE_COMMIT),idevicerestore)

ifneq ($(wildcard $(BUILD_WORK)/idevicerestore/.build_complete),)
idevicerestore:
	@echo "Using previously built idevicerestore."
else
idevicerestore: idevicerestore-setup curl libimobiledevice libirecovery libplist libzip
	cd $(BUILD_WORK)/idevicerestore && ./autogen.sh \
		--build=$(BUILD_MISC)/config.guess \
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
