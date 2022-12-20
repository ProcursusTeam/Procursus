ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

### NOTE: No 32-bit

### TODO: Only builds on Mac.
### TODO: current xcodebuild impl builds way more than needed. This is fine until the codebase stabilizes.
### TODO: write and upstream a Makefile once ellekit stabilizes
### TODO: bundle -dev package
### TODO: Provide migration (dpkg-divert) from LH/Substrate tweakinjector paths to PREFIX/lib/TweakInject on pre-rootless
### TODO: Ensure symlinks are in place for compatibility with Substrate on pre-rootless

### HOLD: reevaluate patches and build steps each release until this is removed

SUBPROJECTS     += ellekit
ELLEKIT_VERSION := 0.1
DEB_ELLEKIT_V   ?= $(ELLEKIT_VERSION)

ELLEKIT_COMMON_XCB := -sdk $(PLATFORM) -configuration Release \
			CODE_SIGN_IDENTITY='' CODE_SIGNING_ALLOWED=NO \
			BUILD_LIBRARIES_FOR_DISTRIBUTION=YES LD="$(CC)" ARCHS="$(MEMO_ARCH)" \
			$(MEMO_DEPLOYMENT)

ellekit-setup: setup
	$(call GITHUB_ARCHIVE,evelyneee,ellekit,$(ELLEKIT_VERSION),v$(ELLEKIT_VERSION))
	$(call EXTRACT_TAR,ellekit-$(ELLEKIT_VERSION).tar.gz,ellekit-$(ELLEKIT_VERSION),ellekit)
	$(call DO_PATCH,ellekit,ellekit,-p1)
	sed -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/ellekit/loader/main.swift \
		$(BUILD_WORK)/ellekit/launchd-hook/{pspawn,TweakList}.m

ifneq ($(wildcard $(BUILD_WORK)/ellekit/.build_complete),)
ellekit:
	@echo "Using previously built ellekit."
else
ellekit: ellekit-setup
ifeq ($(PLATFORM),iphoneos)
	cd $(BUILD_WORK)/ellekit && xcodebuild \
		-target ellekit \
		$(ELLEKIT_COMMON_XCB) ARCHS="arm64 arm64e"
	mv $(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit.a \
		$(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit.dylib
	for target in loader injector pspawn; do \
		cd $(BUILD_WORK)/ellekit && xcodebuild \
			-target $$target $(ELLEKIT_COMMON_XCB); \
	done
else ifeq ($(PLATFORM),macosx)
	cd $(BUILD_WORK)/ellekit && xcodebuild \
		-target ellekit-mac \
		$(ELLEKIT_COMMON_XCB) ARCHS="x86_64 arm64 arm64e"
	for target in loader injector pspawn; do \
		cd $(BUILD_WORK)/ellekit && xcodebuild \
			-target $$target $(ELLEKIT_COMMON_XCB); \
	done
	mv $(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit-mac.dylib \
		$(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit.dylib
else
	@echo "### MEMO: Platform not currently supported for ellekit build"
endif
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libellekit.dylib \
		$(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/pspawn.dylib \
		$(BUILD_WORK)/ellekit/build/Release-iphoneos/libpspawn.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/injector.dylib \
		$(BUILD_WORK)/ellekit/build/Release-iphoneos/libinjector.dylib

	install -Dm755 $(BUILD_WORK)/ellekit/build/Release-iphoneos/loader \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ellekit/loader
	install -Dm644 $(BUILD_WORK)/ellekit/build/Release-iphoneos/libpspawn.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/pspawn.dylib
	install -m644 $(BUILD_WORK)/ellekit/build/Release-iphoneos/libinjector.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/injector.dylib
	install -Dm644 $(BUILD_WORK)/ellekit/build/Release-iphoneos/libellekit.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libellekit.dylib

	ln -s libellekit.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsubstrate.dylib
	ln -s libellekit.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhooker.dylib

	mkdir -p $(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/TweakInject
	$(call AFTER_BUILD)
endif

ellekit-package: ellekit-stage
	# ellekit.mk Package Structure
	rm -rf $(BUILD_DIST)/ellekit

	# ellekit.mk Prep ellekit
	cp -a $(BUILD_STAGE)/ellekit $(BUILD_DIST)

	# ellekit.mk Sign
	$(call SIGN,ellekit,general.xml)

	# ellekit.mk Make .debs
	$(call PACK,ellekit,DEB_ELLEKIT_V)

	# ellekit.mk Build cleanup
	rm -rf $(BUILD_DIST)/ellekit

.PHONY: ellekit ellekit-package
