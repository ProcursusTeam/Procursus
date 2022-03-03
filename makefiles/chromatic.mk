ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
ifeq (,$(findstring rootless,$(MEMO_TARGET)))
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge "1500" ] && echo 1),1)

SUBPROJECTS       += chromatic
CHROMATIC_VERSION := 2.1
CHROMATIC_TAG     := CI-1645604648
DEB_CHROMATIC_V   ?= $(CHROMATIC_VERSION)-REL-$(shell echo $(CHROMATIC_TAG) | cut -d- -f2)-procursus$(CFVER_WHOLE)

# FIXME: Procursus mirrors are broken
chromatic-setup: setup
	$(call GITHUB_ARCHIVE,SailyTeam,Saily,$(CHROMATIC_TAG),$(CHROMATIC_TAG))
	$(call EXTRACT_TAR,Saily-$(CHROMATIC_TAG).tar.gz,Saily-$(CHROMATIC_TAG),chromatic)
	sed -i 's|const char \*privilegedPrefix = "/Applications/";|const char \*privilegedPrefix = "$(MEMO_PREFIX)/Applications/chromatic.app/";|' $(BUILD_WORK)/chromatic/PrivilegeSpawn/rootspawn/ticket.m

ifneq ($(wildcard $(BUILD_WORK)/chromatic/.build_complete),)
chromatic:
	@echo "Using previously built chromatic."
else
chromatic: chromatic-setup
	mkdir -p $(BUILD_STAGE)/chromatic/$(MEMO_PREFIX)/{Applications,$(MEMO_SUB_PREFIX)/sbin}
	cd $(BUILD_WORK)/chromatic/PrivilegeSpawn/rootspawn; \
		$(CC) -x objective-c $(CFLAGS) $(LDFLAGS) -framework Foundation -framework CoreFoundation *.m -o $(BUILD_STAGE)/chromatic/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/chromaticspawn;
	unset CC LD NM AR STRINGS CFLAGS LDFLAGS PLATFORM BARE_PLATFORM PLAFTORM_VERSION_MIN TARGET_SYSROOT MACOSX_SYSROOT; \
		cd $(BUILD_WORK)/chromatic; \
				xcodebuild \
				-workspace Chromatic.xcworkspace \
				-scheme Chromatic \
				-configuration Release \
				-derivedDataPath build \
				-sdk iphoneos \
				CODE_SIGN_IDENTITY="" \
				CODE_SIGNING_REQUIRED=NO \
				CODE_SIGN_ENTITLEMENTS="" \
				CODE_SIGNING_ALLOWED="NO" \
				GCC_GENERATE_DEBUGGING_SYMBOLS=NO \
				PRODUCT_BUNDLE_IDENTIFIER="wiki.qaq.chromatic.release" \
				VALID_ARCHS="$(MEMO_ARCH)"
	plutil -replace "CFBundleDisplayName" -string "Saily" "$(BUILD_WORK)/chromatic/build/Build/Products/Release-iphoneos/chromatic.app/Info.plist"
	plutil -replace "CFBundleIdentifier" -string "wiki.qaq.chromatic.release" "$(BUILD_WORK)/chromatic/build/Build/Products/Release-iphoneos/chromatic.app/Info.plist"
	plutil -replace "CFBundleVersion" -string "$(CHROMATIC_VERSION)" "$(BUILD_WORK)/chromatic/build/Build/Products/Release-iphoneos/chromatic.app/Info.plist"
	plutil -replace "CFBundleShortVersionString" -string "$(shell date +%s)" "$(BUILD_WORK)/chromatic/build/Build/Products/Release-iphoneos/chromatic.app/Info.plist"
	cp -a $(BUILD_WORK)/chromatic/build/Build/Products/Release-iphoneos/chromatic.app $(BUILD_STAGE)/chromatic/$(MEMO_PREFIX)/Applications
	$(call AFTER_BUILD)
endif

chromatic-package: chromatic-stage
	# chromatic.mk Package Structure
	rm -rf $(BUILD_DIST)/chromatic

	# chromatic.mk Prep chromatic
	cp -a $(BUILD_STAGE)/chromatic $(BUILD_DIST)

	# chromatic.mk Sign
	$(call SIGN,chromatic,general.xml)

	# chromatic.mk Permissions
	$(FAKEROOT) chmod 4755 $(BUILD_DIST)/chromatic/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/chromaticspawn;

	# chromatic.mk Make .debs
	$(call PACK,chromatic,DEB_CHROMATIC_V)

	# chromatic.mk Build cleanup
	rm -rf $(BUILD_DIST)/chromatic

.PHONY: chromatic chromatic-package

endif
endif
endif
endif
