ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += build-essential

ifneq ($(wildcard $(BUILD_WORK)/build-essential/.build_complete),)
build-essential:
	@echo "Using previously built build-essential."
else
build-essential: setup
	mkdir -p $(BUILD_WORK)/build-essential
	mkdir -p $(BUILD_STAGE)/build-essential/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/$(BARE_PLATFORM).sdk
	cp -a $(TARGET_SYSROOT)/* $(BUILD_STAGE)/build-essential/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/$(BARE_PLATFORM).sdk
	touch $(BUILD_WORK)/build-essential/.build_complete
endif

build-essential-package: build-essential-stage
	# Set version info
	$(eval DEB_BUILD-ESSENTIAL_V := $(shell /usr/libexec/PlistBuddy -c "Print :MinimalDisplayName" $(TARGET_SYSROOT)/SDKSettings.plist))

	# build-essential.mk Package Structure
	rm -rf $(BUILD_DIST)/build-essential

	# build-essential.mk Prep build-essential
	cp -a $(BUILD_STAGE)/build-essential $(BUILD_DIST)

	# build-essential.mk Make .debs
	$(call PACK,build-essential,DEB_BUILD-ESSENTIAL_V)

	# build-essential.mk Build cleanup
	rm -rf $(BUILD_DIST)/build-essential

.PHONY: build-essential build-essential-package
