ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

XZ_VERSION := 5.2.4
DEB_XZ_V   ?= $(XZ_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/xz/.build_complete),)
xz:
	@echo "Using previously built xz."
else
xz: setup
	cd $(BUILD_WORK)/xz && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr/local \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-silent-rules
	$(MAKE) -C $(BUILD_WORK)/xz
	$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_STAGE)/xz
	$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xz/.build_complete
endif

xz-package: xz-stage
	# xz.mk Package Structure
	rm -rf $(BUILD_DIST)/xz-utils
	mkdir -p $(BUILD_DIST)/xz-utils
	
	# xz.mk Prep xz-utils
	$(FAKEROOT) cp -a $(BUILD_STAGE)/xz/usr $(BUILD_DIST)/xz-utils
	
	# xz.mk Sign
	$(call SIGN,xz-utils,general.xml)
	
	# xz.mk Make .debs
	$(call PACK,xz-utils,DEB_XZ_V)
	
	# xz.mk Build cleanup
	rm -rf $(BUILD_DIST)/xz-utils

.PHONY: xz xz-package
