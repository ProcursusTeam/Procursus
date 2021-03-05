ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS      += theos-dependencies
THEOSDEPS_VERSION  := 0-1
DEB_THEOSDEPS_V    ?= $(THEOSDEPS_VERSION)

theos-dependencies:
    @echo "Theos Dependencies is just a control file"

theos-dependencies-package: theos-dependencies-stage
    # theos-dependencies.mk Package Structure
    rm -rf $(BUILD_DIST)/ios-toolchain
    mkdir -p $(BUILD_DIST)/ios-toolchain

    rm -rf $(BUILD_DIST)/theos-dependencies
    mkdir -p $(BUILD_DIST)/theos-dependencies

    # theos-dependencies.mk Make .debs
    $(call PACK,ios-toolchain,DEB_THEOSDEPS_V)
    $(call PACK,theos-dependencies,DEB_THEOSDEPS_V)

    # theos-dependencies.mk Build cleanup
    rm -rf $(BUILD_DIST)/ios-toolchain
    rm -rf $(BUILD_DIST)/theos-dependencies

.PHONY: theos-dependencies theos-dependencies-package
