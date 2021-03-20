ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(MEMO_TARGET),iphoneos-arm64)
ifeq ($(UNAME),Darwin)
ifeq ($(filter $(shell uname -m | cut -c -4), iPad iPho),)

SUBPROJECTS             += pojavlauncher
POJAVLAUNCHER_COMMIT    := 6423825f3106c107d806c39159e8b6aa1868c677
POJAVLAUNCHER_VERSION   := 1.1+git20210304.$(shell echo $(POJAVLAUNCHER_COMMIT) | cut -c -7)
DEB_POJAVLAUNCHER_V     ?= $(POJAVLAUNCHER_VERSION)

pojavlauncher-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz \
			https://github.com/PojavLauncherTeam/PojavLauncher_iOS/archive/$(POJAVLAUNCHER_COMMIT).tar.gz
	$(call EXTRACT_TAR,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT),pojavlauncher)
	mkdir -p $(BUILD_STAGE)/pojavlauncher/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}

ifneq ($(wildcard $(BUILD_WORK)/pojavlauncher/.build_complete),)
pojavlauncher:
	@echo "Using previously built pojavlauncher."
else
pojavlauncher: pojavlauncher-setup
	# Reimplement the build script
	cd $(BUILD_WORK)/pojavlauncher; \
		chmod 755 *.sh && \
		unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS; \
		cd Natives; \
			mkdir -p build; \
			cd build; \
			wget https://github.com/leetal/ios-cmake/raw/master/ios.toolchain.cmake; \
			cmake .. -G Xcode -DDEPLOYMENT_TARGET=$(IPHONEOS_DEPLOYMENT_TARGET) -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=OS64 -DENABLE_BITCODE=FALSE -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED="NO" -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=""; \
			cmake --build . --config Release --target pojavexec PojavLauncher; \
			cd ../..; \
			mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj; \
			ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard; \
			mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks; \
			cp Natives/build/Release-iphoneos/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/; \
			cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/; \
		cd JavaApp; \
			chmod +x gradlew; \
			./gradlew clean build; \
			cd ..; \
		mkdir Natives/build/Release-iphoneos/PojavLauncher.app/libs; \
		cp JavaApp/build/libs/PojavLauncher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/launcher.jar; \
		cp JavaApp/libs/* Natives/build/Release-iphoneos/PojavLauncher.app/libs/;
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