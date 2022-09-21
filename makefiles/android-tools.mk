ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += android-tools
ANDROID_TOOLS_VERSION := 31.0.3p2
DEB_ANDROID_TOOLS_V   ?= $(ANDROID_TOOLS_VERSION)

# XXX: It looks like the build system does not build shared libraries.

android-tools-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/nmeum/android-tools/releases/download/$(ANDROID_TOOLS_VERSION)/android-tools-$(ANDROID_TOOLS_VERSION).tar.xz)
	$(call EXTRACT_TAR,android-tools-$(ANDROID_TOOLS_VERSION).tar.xz,android-tools-$(ANDROID_TOOLS_VERSION),android-tools)
	$(call DO_PATCH,android-tools,android-tools,-p1)
	mkdir -p $(BUILD_WORK)/android-tools/build

ifneq ($(call HAS_COMMAND,protoc),1)
android-tools:
	$(error Install protobuf-compiler)
else ifneq ($(call HAS_COMMAND,go),1)
android-tools:
	$(error Install the go compiler)
else ifneq ($(wildcard $(BUILD_WORK)/android-tools/.build_complete),)
android-tools:
	@echo "Using previously built android-tools."
else
android-tools: android-tools-setup libusb pcre2 googletest libprotobuf brotli zstd lz4
	cd $(BUILD_WORK)/android-tools/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS='$(CXXFLAGS) $(PLATFORM_VERSION_MIN) -D_DARWIN_C_SOURCE -D__DARWIN_C_LEVEL=__DARWIN_C_FULL -std=gnu++20' \
		-DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS) -framework CoreFoundation -framework IOKit" \
		..
	+sed -i 's|$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/protoc|$(shell command -v protoc)|g' $$(find $(BUILD_WORK)/android-tools -name build.make)
	+sed -i 's|$(shell echo $(PLATFORM_VERSION_MIN) | cut -d= -f1)=$(MACOSX_DEPLOYMENT_TARGET)|$(PLATFORM_VERSION_MIN)|g' $$(find $(BUILD_WORK)/android-tools -name flags.make)
	+$(MAKE) -C $(BUILD_WORK)/android-tools/build
	+$(MAKE) -C $(BUILD_WORK)/android-tools/build install \
		DESTDIR="$(BUILD_STAGE)/android-tools"
	$(call AFTER_BUILD)
endif

android-tools-package: android-tools-stage
	# android-tools.mk Package Structure
	rm -rf $(BUILD_DIST)/{adb,fastboot,mkbootimg,android-sdk-libsparse-utils,android-sdk-platform-tools}
	mkdir -p $(BUILD_DIST)/{adb,fastboot,mkbootimg,android-sdk-libsparse-utils,android-sdk-platform-tools}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/{adb,fastboot}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{android-tools,bash-completion}/completions

	# android-tools.mk Prep adb
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/adb $(BUILD_DIST)/adb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/android-tools/completions/adb $(BUILD_DIST)/adb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/android-tools/completions
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/adb $(BUILD_DIST)/adb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions

	# android-tools.mk Prep fastboot
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fastboot $(BUILD_DIST)/fastboot/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/android-tools/completions/fastboot $(BUILD_DIST)/fastboot/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/android-tools/completions
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/fastboot $(BUILD_DIST)/fastboot/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions

	# android-tools.mk Prep mkbootimg
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{mk,unpack_,repack_}bootimg $(BUILD_DIST)/mkbootimg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# android-tools.mk Prep android-sdk-libsparse-utils
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{append2simg,img2simg,simg2img,ext2simg} $(BUILD_DIST)/android-sdk-libsparse-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# android-tools.mk Prep android-sdk-platform-tools
	cp -a $(BUILD_STAGE)/android-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{lpadd,lpdump,lpflash,lpmake,lpunpack,mke2fs.android} $(BUILD_DIST)/android-sdk-libsparse-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# android-tools.mk Sign
	$(call SIGN,adb,usb.xml)
	$(call SIGN,fastboot,usb.xml)
	$(call SIGN,android-sdk-libsparse-utils,general.xml)
	$(call SIGN,android-sdk-platform-tools,dd.xml)

	# android-tools.mk Make .debs
	$(call PACK,adb,DEB_ANDROID_TOOLS_V)
	$(call PACK,fastboot,DEB_ANDROID_TOOLS_V)
	$(call PACK,mkbootimg,DEB_ANDROID_TOOLS_V)
	$(call PACK,android-sdk-libsparse-utils,DEB_ANDROID_TOOLS_V)
	$(call PACK,android-sdk-platform-tools,DEB_ANDROID_TOOLS_V)

	# android-tools.mk Build cleanup
	rm -rf $(BUILD_DIST)/{adb,fastboot,mkbootimg,android-sdk-libsparse-utils,android-sdk-platform-tools}

.PHONY: android-tools android-tools-package
