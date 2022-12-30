ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += xcodegen
XCODEGEN_VERSION := 2.32.0
DEB_XCODEGEN_V   ?= $(XCODEGEN_VERSION)

xcodegen-setup: setup
	$(call GITHUB_ARCHIVE,yonaskolb,XcodeGen,$(XCODEGEN_VERSION),$(XCODEGEN_VERSION))
	$(call EXTRACT_TAR,xcodegen-$(XCODEGEN_VERSION).tar.gz,xcodegen-$(XCODEGEN_VERSION),xcodegen)

ifneq ($(wildcard $(BUILD_WORK)/xcodegen/.build_complete),)
xcodegen:
	@echo "Using previously built xcodegen."
else
xcodegen: xcodegen-setup
	cd $(BUILD_WORK)/xcodegen && swift build -c release --sdk=$(MACOSX_SYSROOT) --arch=$(MEMO_ARCH) --disable-sandbox
	mkdir -p $(BUILD_STAGE)/xcodegen/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	install -Dm755 $(BUILD_WORK)/xcodegen/.build/release/xcodegen $(BUILD_STAGE)/xcodegen/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

xcodegen-package: xcodegen-stage
	# xcodegen.mk Package Structure
	rm -rf $(BUILD_DIST)/xcodegen

	# xcodegen.mk Prep xcodegen
	cp -a $(BUILD_STAGE)/xcodegen $(BUILD_DIST)

	# xcodegen.mk Sign
	$(call SIGN,xcodegen,general.xml)

	# xcodegen.mk Make .debs
	$(call PACK,xcodegen,DEB_XCODEGEN_V)

	# xcodegen.mk Build cleanup
	rm -rf $(BUILD_DIST)/xcodegen

.PHONY: xcodegen xcodegen-package

 endif # ($(MEMO_TARGET),darwin-\*)