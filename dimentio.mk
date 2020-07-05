ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBROJECTS       += dimentio
DIMENTIO_VERSION := 1.1
DEB_DIMENTIO_V   ?= $(DIMENTIO_VERSION)

dimentio-setup: setup
	rm -rf $(BUILD_WORK)/dimentio
	mkdir -p $(BUILD_WORK)/dimentio
	cp -af dimentio/* $(BUILD_WORK)/dimentio
	$(SED) -i '5d' $(BUILD_WORK)/dimentio/Makefile
	$(SED) -i 's/-arch arm64e//g' $(BUILD_WORK)/dimentio/Makefile

ifneq ($(wildcard $(BUILD_WORK)/dimentio/.build_complete),)
dimentio:
	@echo "Using previously built dimentio."
else
dimentio: dimentio-setup
	cd $(BUILD_WORK)/dimentio && $(MAKE)
	mkdir -p $(BUILD_STAGE)/dimentio/usr/bin
	cp -a $(BUILD_WORK)/dimentio/dimentio $(BUILD_STAGE)/dimentio/usr/bin
	touch $(BUILD_WORK)/dimentio/.build_complete
endif

dimentio-package: dimentio-stage
	# dimentio.mk Package Structure
	rm -rf $(BUILD_DIST)/dimentio
	mkdir -p $(BUILD_DIST)/dimentio/usr/bin
	
	# dimentio.mk Prep dimentio
	cp -a $(BUILD_STAGE)/dimentio/usr $(BUILD_DIST)/dimentio
	
	# dimentio.mk Sign
	$(call SIGN,dimentio,tfp0.xml)

	# dimentio.mk Make .debs
	$(call PACK,dimentio,DEB_DIMENTIO_V)
	
	# dimentio.mk Build cleanup
	rm -rf $(BUILD_DIST)/dimentio

.PHONY: dimentio dimentio-package
