ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += plutil
DEB_PLUTIL_V ?= $(SWIFT_VERSION)~$(SWIFT_SUFFIX)

plutil-setup: setup
	$(call GITHUB_ARCHIVE,apple,swift-corelibs-foundation,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),plutil)
	$(call EXTRACT_TAR,plutil-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-corelibs-foundation-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),plutil)
	sed -i 's|SwiftFoundation|Foundation|g' $(BUILD_WORK)/plutil/Sources/Tools/plutil/main.swift
	mkdir -p $(BUILD_STAGE)/plutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/plutil/.build_complete),)
plutil:
	@echo "Using previously built plutil."
else
plutil: plutil-setup
	cd $(BUILD_WORK)/plutil/Sources/Tools/plutil; \
		swiftc -Osize --target=$(LLVM_TARGET) -sdk $(TARGET_SYSROOT) -o $(BUILD_STAGE)/plutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/plutil main.swift
	$(call AFTER_BUILD)
endif

plutil-package: plutil-stage
	# plutil.mk Package Structure
	rm -rf $(BUILD_DIST)/plutil
	
	# plutil.mk Prep plutil
	cp -a $(BUILD_STAGE)/plutil $(BUILD_DIST)
	
	# plutil.mk Sign
	$(call SIGN,plutil,general.xml)
	
	# plutil.mk Make .debs
	$(call PACK,plutil,DEB_PLUTIL_V)
	
	# plutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/plutil

.PHONY: plutil plutil-package
