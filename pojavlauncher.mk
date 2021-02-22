ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(MEMO_TARGET),iphoneos-arm64)
ifeq ($(UNAME),Darwin)
ifeq ($(filter $(shell uname -m | cut -c -4), iPad iPho),)

SUBPROJECTS             += pojavlauncher
POJAVLAUNCHER_COMMIT    := 81d8360c71feba3e14a0470f0db776d374428f55
POJAVLAUNCHER_VERSION   := 1.0+git20210222.$(shell echo $(POJAVLAUNCHER_COMMIT) | cut -c -7)
DEB_POJAVLAUNCHER_V     ?= $(POJAVLAUNCHER_VERSION)

pojavlauncher-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz \
			https://github.com/PojavLauncherTeam/PojavLauncher_iOS/archive/$(POJAVLAUNCHER_COMMIT).tar.gz
	$(call EXTRACT_TAR,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT),pojavlauncher)
	$(SED) -i '/-G Xcode/ s/$$/ -DDEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET)/' $(BUILD_WORK)/pojavlauncher/build_natives.sh
	mkdir -p $(BUILD_STAGE)/pojavlauncher/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}

ifneq ($(wildcard $(BUILD_WORK)/pojavlauncher/.build_complete),)
pojavlauncher:
	@echo "Using previously built pojavlauncher."
else
pojavlauncher: pojavlauncher-setup
	cd $(BUILD_WORK)/pojavlauncher; \
		chmod 755 *.sh && \
		env -i DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET) ./build_natives.sh && \
		DEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET) ./build_javaapp.sh
	cp -R $(BUILD_WORK)/pojavlauncher/Natives/build/Release-iphoneos/PojavLauncher.app $(BUILD_STAGE)/pojavlauncher/Applications
	touch $(BUILD_WORK)/pojavlauncher/.build_complete
endif

pojavlauncher-package: pojavlauncher-stage
	# pojavlauncher.mk Package Structure
	rm -rf $(BUILD_DIST)/pojavlauncher

	# pojavlauncher.mk Prep pojavlauncher
	cp -a $(BUILD_STAGE)/pojavlauncher $(BUILD_DIST)

	# pojavlauncher.mk Sign
	$(call SIGN,pojavlauncher,qemu-ios.xml)

	# base.mk Permissions
	$(FAKEROOT) chown -R 501:501 $(BUILD_DIST)/pojavlauncher/var/mobile

	# pojavlauncher.mk Make .debs
	$(call PACK,pojavlauncher,DEB_POJAVLAUNCHER_V,2)

	# pojavlauncher.mk Build cleanup
	rm -rf $(BUILD_DIST)/pojavlauncher

.PHONY: pojavlauncher pojavlauncher-package

endif # ($(filter $(shell uname -m | cut -c -4), iPad iPho),)
endif # ($(UNAME),Darwin)
endif # ($(MEMO_TARGET),iphoneos-arm64)