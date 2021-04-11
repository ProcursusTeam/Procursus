ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += ideviceinstaller
IDEVICEINSTALLER_VERSION := 1.1.1
DEB_IDEVICEINSTALLER_V   ?= $(IDEVICEINSTALLER_VERSION)-1

ideviceinstaller-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/ideviceinstaller/releases/download/$(IDEVICEINSTALLER_VERSION)/ideviceinstaller-$(IDEVICEINSTALLER_VERSION).tar.bz2
	$(call EXTRACT_TAR,ideviceinstaller-$(IDEVICEINSTALLER_VERSION).tar.bz2,ideviceinstaller-$(IDEVICEINSTALLER_VERSION),ideviceinstaller)
	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/ideviceinstaller/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/ideviceinstaller/.build_complete),)
ideviceinstaller:
	@echo "Using previously built ideviceinstaller."
else
ideviceinstaller: ideviceinstaller-setup libzip libplist libimobiledevice
	cd $(BUILD_WORK)/ideviceinstaller && autoreconf -fi
	cd $(BUILD_WORK)/ideviceinstaller && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/ideviceinstaller V=1
	+$(MAKE) -C $(BUILD_WORK)/ideviceinstaller install \
		DESTDIR=$(BUILD_STAGE)/ideviceinstaller
	touch $(BUILD_WORK)/ideviceinstaller/.build_complete
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
