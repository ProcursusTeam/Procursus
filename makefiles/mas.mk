ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS += mas
MAS_VERSION := 1.8.6
DEB_MAS_V   ?= $(MAS_VERSION)

mas-setup: setup
	$(call GITHUB_ARCHIVE,mas-cli,mas,v$(MAS_VERSION),v$(MAS_VERSION))
	$(call EXTRACT_TAR,mas-v$(MAS_VERSION).tar.gz,mas-$(MAS_VERSION),mas)

ifneq ($(wildcard $(BUILD_WORK)/mas/.build_complete),)
mas:
	@echo "Using previously built mas."
else
mas: mas-setup

ifneq (,$(shell dpkg -l | grep libncurses-dev))
$(error mas will fail to build with libncurses-dev installed)
else
	printf "enum Package { \n\t static let version = \"$(MAS_VERSION)\"\n}" > $(BUILD_WORK)/mas/Sources/MasKit/Package.swift
	mkdir -p $(BUILD_STAGE)/mas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
# cd $(BUILD_WORK)/mas && swift build -c release --sdk $(TARGET_SYSROOT) --arch=$(MEMO_ARCH) --disable-sandbox
	cd $(BUILD_WORK)/mas && swift build -c release \
		-Xswiftc "-Osize" \
		-Xswiftc "--target=$(LLVM_TARGET)" \
		-Xswiftc "-I$(TARGET_SYSROOT)/usr/include" 
	install -Dm755 $(BUILD_WORK)/mas/.build/release/mas $(BUILD_STAGE)/mas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif
endif

mas-package: mas-stage
	# mas.mk Package Structure
	rm -rf $(BUILD_DIST)/mas

	# mas.mk Prep mas
	cp -a $(BUILD_STAGE)/mas $(BUILD_DIST)

	# mas.mk Sign
	$(call SIGN,mas,general.xml)

	# mas.mk Make .debs
	$(call PACK,mas,DEB_MAS_V)

	# mas.mk Build cleanup
	rm -rf $(BUILD_DIST)/mas

.PHONY: mas mas-package

endif # ($(MEMO_TARGET),darwin-\*