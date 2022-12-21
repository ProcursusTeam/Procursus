ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

### NOTE: No 32-bit or arm64e

### TODO: Only builds on Mac.
### TODO: current xcodebuild impl builds way more than needed. This is fine until the codebase stabilizes.
### TODO: write and upstream a Makefile once ellekit stabilizes
### TODO: bundle -dev package
### TODO: Provide migration (dpkg-divert) from LH/Substrate tweakinjector paths to PREFIX/lib/TweakInject on pre-rootless
### TODO: Ensure symlinks are in place for compatibility with Substrate on pre-rootless

### HOLD: reevaluate patches and build steps each release until this is removed

SUBPROJECTS     += ellekit
ELLEKIT_COMMIT  := 5fe185d0f83da32570d4b89ba1c3cde6062e8c33
ELLEKIT_VERSION := 0.1+git20221221.$(shell echo $(ELLEKIT_COMMIT) | cut -c -7)
DEB_ELLEKIT_V   ?= $(ELLEKIT_VERSION)

ELLEKIT_COMMON_XCB := -sdk $(PLATFORM) -configuration Release \
			CODE_SIGN_IDENTITY='' CODE_SIGNING_ALLOWED=NO \
			BUILD_LIBRARIES_FOR_DISTRIBUTION=YES LD="$(CC)" ARCHS="$(MEMO_ARCH)" \
			$(MEMO_DEPLOYMENT)

ellekit-setup: setup
	$(call GITHUB_ARCHIVE,evelyneee,ellekit,$(ELLEKIT_COMMIT),$(ELLEKIT_COMMIT))
	$(call EXTRACT_TAR,ellekit-$(ELLEKIT_COMMIT).tar.gz,ellekit-$(ELLEKIT_COMMIT),ellekit)
#	$(call DO_PATCH,ellekit,ellekit,-p1)

ifneq ($(wildcard $(BUILD_WORK)/ellekit/.build_complete),)
ellekit:
	@echo "Using previously built ellekit."
else
ellekit: ellekit-setup
ifeq ($(PLATFORM),iphoneos)
	for target in launchd ellekit; do \
		cd $(BUILD_WORK)/ellekit && xcodebuild \
			-target $$target \
			$(ELLEKIT_COMMON_XCB) ARCHS="arm64 arm64e"; \
	done
else ifeq ($(PLATFORM),macosx)
	for target in launchd ellekit; do \
		cd $(BUILD_WORK)/ellekit && xcodebuild \
			-target $$target \
			$(ELLEKIT_COMMON_XCB) ARCHS="arm64 arm64e x86_64"; \
	done
else
	@echo "### MEMO: Platform not currently supported for ellekit build"
endif

	cd $(BUILD_WORK)/ellekit && xcodebuild \
		-target loader $(ELLEKIT_COMMON_XCB)

	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libellekit.dylib \
		$(BUILD_WORK)/ellekit/build/Release*/libellekit.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/pspawn.dylib \
		$(BUILD_WORK)/ellekit/build/Release*/liblaunchd.dylib

	install -Dm755 $(BUILD_WORK)/ellekit/build/Release*/loader \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ellekit/loader
	install -Dm644 $(BUILD_WORK)/ellekit/build/Release*/liblaunchd.dylib \
		$(BUILD_STAGE)/ellekit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ellekit/pspawn.dylib
	install -Dm644 $(BUILD_WORK)/ellekit/build/Release*/libellekit.dylib \
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
	$(call SIGN,ellekit,tfp0.xml)

	# ellekit.mk Make .debs
	$(call PACK,ellekit,DEB_ELLEKIT_V)

	# ellekit.mk Build cleanup
	rm -rf $(BUILD_DIST)/ellekit

.PHONY: ellekit ellekit-package
