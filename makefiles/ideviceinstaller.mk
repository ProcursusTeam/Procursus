ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += ideviceinstaller
IDEVICEINSTALLER_COMMIT  := 659e35c047278661aedb4d4688f4d3aad5892cc2
IDEVICEINSTALLER_VERSION := 1.1.1+git20210629.$(shell echo $(IDEVICERESTORE_COMMIT) | cut -c -7)
DEB_IDEVICEINSTALLER_V   ?= $(IDEVICEINSTALLER_VERSION)

ideviceinstaller-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,ideviceinstaller,$(IDEVICEINSTALLER_COMMIT),$(IDEVICEINSTALLER_COMMIT))
	$(call EXTRACT_TAR,ideviceinstaller-$(IDEVICEINSTALLER_COMMIT).tar.gz,ideviceinstaller-$(IDEVICEINSTALLER_COMMIT),ideviceinstaller)
	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/ideviceinstaller/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/ideviceinstaller/.build_complete),)
ideviceinstaller:
	@echo "Using previously built ideviceinstaller."
else
ideviceinstaller: ideviceinstaller-setup libzip libplist libimobiledevice
	cd $(BUILD_WORK)/ideviceinstaller && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/ideviceinstaller V=1
	+$(MAKE) -C $(BUILD_WORK)/ideviceinstaller install \
		DESTDIR=$(BUILD_STAGE)/ideviceinstaller
	$(call AFTER_BUILD)
endif

ideviceinstaller-package: ideviceinstaller-stage
	# ideviceinstaller.mk Package Structure
	rm -rf $(BUILD_DIST)/ideviceinstaller

	# ideviceinstaller.mk Prep ideviceinstaller
	cp -a $(BUILD_STAGE)/ideviceinstaller $(BUILD_DIST)

	# ideviceinstaller.mk Sign
	$(call SIGN,ideviceinstaller,general.xml)

	# ideviceinstaller.mk Make .debs
	$(call PACK,ideviceinstaller,DEB_IDEVICEINSTALLER_V)

	# ideviceinstaller.mk Build cleanup
	rm -rf $(BUILD_DIST)/ideviceinstaller

.PHONY: ideviceinstaller ideviceinstaller-package
