ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
ifeq ($(UNAME),Darwin)
ifeq ($(filter $(shell uname -m | cut -c -4), iPad iPho),)

SUBPROJECTS             += pojavlauncher
POJAVLAUNCHER_COMMIT    := 14c756987d4c9f797e22b0c784627d7030e238e7
POJAVLAUNCHER_VERSION   := 1.2
#+git20210417.$(shell echo $(POJAVLAUNCHER_COMMIT) | cut -c -7)
DEB_POJAVLAUNCHER_V     ?= $(POJAVLAUNCHER_VERSION)

JAVAFILES   := $(shell cd JavaApp; find src -type f -name "*.java" -print)

pojavlauncher-setup: setup
	$(call GITHUB_ARCHIVE,PojavLauncherTeam,PojavLauncher_iOS,$(POJAVLAUNCHER_COMMIT),$(POJAVLAUNCHER_COMMIT))
	$(call EXTRACT_TAR,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT).tar.gz,PojavLauncher_iOS-$(POJAVLAUNCHER_COMMIT),pojavlauncher)
	mkdir -p $(BUILD_STAGE)/pojavlauncher/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}
#	for file in $(BUILD_WORK)/pojavlauncher/Natives/JavaLauncher.c \
#	$(BUILD_WORK)/pojavlauncher/JavaApp/src/main/java/net/kdt/pojavlaunch/Tools.java; do \
#		$(SED) -i 's/java-16-openjdk/java-17-openjdk/' $$file; \
#	done

ifneq ($(wildcard $(BUILD_WORK)/pojavlauncher/.build_complete),)
pojavlauncher:
	@echo "Using previously built pojavlauncher."
else
pojavlauncher: pojavlauncher-setup
	# Copy and paste from the new Makefile... basically
	cd $(BUILD_WORK)/pojavlauncher; \
		unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS; \
		cd Natives; \
			mkdir -p build; \
			cd build; \
			cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_CROSSCOMPILING=true -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_OSX_SYSROOT="$(SDKPATH)" -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_C_FLAGS="-arch arm64 -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)" ..
			cmake --build . --config Release --target pojavexec PojavLauncher; \
			cd ../..; \
			mkdir -p Natives/build/PojavLauncher.app/Base.lproj; \
			actool Natives/Assets.xcassets --compile Natives/resources --platform iphoneos --minimum-deployment-target $(IPHONEOS_DEPLOYMENT_TARGET) --app-icon AppIcon --output-partial-info-plist /dev/null; \
			ibtool --compile Natives/build/PojavLauncher.app/Base.lproj/LaunchScreen.storyboardc Natives/en.lproj/LaunchScreen.storyboard; \
			ibtool --compile Natives/build/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard; \
			mkdir -p Natives/build/PojavLauncher.app/Frameworks; \
			cp Natives/build/libpojavexec.dylib Natives/build/PojavLauncher.app/Frameworks/; \
			cp -R Natives/resources/* Natives/build/PojavLauncher.app/; \
		cd JavaApp; \
			cd JavaApp; \
			mkdir -p local_out/classes; \
			javac -cp "libs/*" -d local_out/classes $(JAVAFILES); \
			cd local_out/classes; \
			jar -cf ../launcher.jar *; \
		mkdir Natives/build/PojavLauncher.app/{libs,libs_caciocavallo}; \
		cp -R JavaApp/build/local_out/launcher.jar Natives/build/PojavLauncher.app/libs/launcher.jar; \
		cp -R JavaApp/libs/* Natives/build/PojavLauncher.app/libs/; \
		cp -R JavaApp/libs_caciocavallo/* Natives/build/PojavLauncher.app/libs_caciocavallo/;
	cp -R $(BUILD_WORK)/pojavlauncher/Natives/build/PojavLauncher.app $(BUILD_STAGE)/pojavlauncher/Applications
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
endif # (,$(findstring iphoneos,$(MEMO_TARGET)))
