ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += build-essential
BUILD-ESSENTIAL_VERSION := 1
DEB_BUILD-ESSENTIAL_V   ?= $(BUILD-ESSENTIAL_VERSION)

ifeq ($(PLATFORM),iphoneos)
BARE_PLATFORM := iPhoneOS
else ifeq ($(PLATFORM),appletvos)
BARE_PLATFORM := AppleTVOS
else ifeq ($(PLATFORM),watchos)
BARE_PLATFORM := WatchOS
else
$(error Unsupported platform $(PLATFORM))
endif

ifneq ($(wildcard $(BUILD_WORK)/build-essential/.build_complete),)
build-essential:
	@echo "Using previously built build-essential."
else
build-essential: setup
	mkdir -p $(BUILD_WORK)/build-essential/$(MEMO_PREFIX)/{$(MEMO_SUB_PREFIX)/share/SDKs,etc/profile.d}
	$(SED) -E 's|@@PLATFORM@@|$(BARE_PLATFORM)|' < $(BUILD_INFO)/sdkroot.sh.in > $(BUILD_WORK)/build-essential/etc/profile.d/sdkroot.sh
	touch $(BUILD_WORK)/build-essential/.build_complete
endif

build-essential-package: build-essential-stage
	# build-essential.mk Package Structure
	rm -rf $(BUILD_DIST)/build-essential
	mkdir -p $(BUILD_DIST)/build-essential/$(MEMO_PREFIX)
	
	# build-essential.mk Prep build-essential
	cp -a $(BUILD_WORK)/build-essential/$(MEMO_PREFIX)/{etc,$(MEMO_SUB_PREFIX)} $(BUILD_DIST)/build-essential/$(MEMO_PREFIX)
	
	# build-essential.mk Make .debs
	$(call PACK,build-essential,DEB_BUILD-ESSENTIAL_V)
	
	# build-essential.mk Build cleanup
	rm -rf $(BUILD_DIST)/build-essential

.PHONY: build-essential build-essential-package
