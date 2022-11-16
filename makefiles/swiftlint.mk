ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS       += swiftlint
SWIFTLINT_VERSION := 0.49.1
DEB_SWIFTLINT_V   ?= $(SWIFTLINT_VERSION)

swiftlint-setup: setup
	$(call GITHUB_ARCHIVE,realm,SwiftLint,$(SWIFTLINT_VERSION),$(SWIFTLINT_VERSION))
	$(call EXTRACT_TAR,swiftlint-$(SWIFTLINT_VERSION).tar.gz,swiftlint-$(SWIFTLINT_VERSION),swiftlint)

ifneq ($(wildcard $(BUILD_WORK)/swiftlint/.build_complete),)
swiftlint:
	@echo "Using previously built swiftlint."
else
swiftlint: swiftlint-setup
	mkdir -p $(BUILD_WORK)/swiftlint/.build
	mkdir -p $(BUILD_STAGE)/swiftlint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cd $(BUILD_WORK)/swiftlint/ && swift build -c release \
		--arch=$(MEMO_ARCH) \
		-Xlinker -dead_strip \
		-Xswiftc -sdk -Xswiftc $(TARGET_SYSROOT) \
		-Xswiftc -target -Xswiftc $(LLVM_TARGET)
	strip -rSTX "$(BUILD_WORK)/swiftlint/.build/release/swiftlint"
	install -Dm755 $(BUILD_WORK)/swiftlint/.build/release/swiftlint $(BUILD_STAGE)/swiftlint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

swiftlint-package: swiftlint-stage
	# swiftlint.mk Package Structure
	rm -rf $(BUILD_DIST)/swiftlint

	# swiftlint.mk Prep swiftlint
	cp -a $(BUILD_STAGE)/swiftlint $(BUILD_DIST)

	# swiftlint.mk Sign
	$(call SIGN,swiftlint,general.xml)

	# swiftlint.mk Make .debs
	$(call PACK,swiftlint,DEB_SWIFTLINT_V)

	# swiftlint.mk Build cleanup
	rm -rf $(BUILD_DIST)/swiftlint

.PHONY: swiftlint swiftlint-package

endif # ($(MEMO_TARGET),darwin-\*
