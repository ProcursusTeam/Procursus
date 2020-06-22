ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += img4lib
DOWNLOAD           += https://github.com/xerub/img4lib/archive/$(IMG4LIB_VERSION).tar.gz
IMG4LIB_VERSION := master
DEB_IMG4LIB_V   ?= $(IMG4LIB_VERSION)

img4lib-setup: setup
	$(call EXTRACT_TAR,$(IMG4LIB_VERSION).tar.gz,img4lib-$(IMG4LIB_VERSION),img4lib)

ifneq ($(wildcard $(BUILD_WORK)/img4lib/.build_complete),)
img4lib:
	@echo "Using previously built img4lib."
else
img4lib: img4lib-setup openssl
	cd $(BUILD_WORK)/img4lib
	+$(MAKE) -C $(BUILD_WORK)/img4lib
	+$(MAKE) -C $(BUILD_WORK)/img4lib install \
		DESTDIR="$(BUILD_STAGE)/img4lib"
	touch $(BUILD_WORK)/img4lib/.build_complete
endif

img4lib-package: img4lib-stage
	# img4lib.mk Package Structure
	rm -rf $(BUILD_DIST)/img4lib
	mkdir -p $(BUILD_DIST)/img4lib
	
	# img4lib.mk Prep img4lib
	cp -a $(BUILD_STAGE)/img4lib/usr $(BUILD_DIST)/img4lib
	
	# img4lib.mk Sign
	$(call SIGN,img4lib,general.xml)
	
	# img4lib.mk Make .debs
	$(call PACK,img4lib,DEB_IMG4LIB_V)
	
	# img4lib.mk Build cleanup
	rm -rf $(BUILD_DIST)/img4lib

.PHONY: img4lib img4lib-package
