ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ipsw
IPSW_VERSION  := 3.1.506
DEB_IPSW_V    ?= $(IPSW_VERSION)

ipsw-setup: setup
	$(call GITHUB_ARCHIVE,blacktop,ipsw,v$(IPSW_VERSION),v$(IPSW_VERSION))
	$(call EXTRACT_TAR,ipsw-v$(IPSW_VERSION).tar.gz,ipsw-$(IPSW_VERSION),ipsw)
	sed -i 's/arm64e-ios ]/arm64e-ios, arm64-tvos, arm64e-tvos, armv7k-watchos, arm64-watchos, arm64e-watchos ]/g' $(BUILD_WORK)/ipsw/internal/apsd/ApplePushService.tbd
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's|/System/Library/PrivateFrameworks/ApplePushService.framework/Versions/A/ApplePushService|/System/Library/PrivateFrameworks/ApplePushService.framework/ApplePushService|g' $(BUILD_WORK)/ipsw/internal/apsd/ApplePushService.tbd
endif

ifneq ($(wildcard $(BUILD_WORK)/ipsw/.build_complete),)
ipsw:
	@echo "Using previously built ipsw."
else
ipsw: ipsw-setup libusb unicorn
	mkdir -p $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{man/man1,zsh/site-functions,bash-completion/completions,fish/vendor_completions.d}}
	cd $(BUILD_WORK)/ipsw && $(DEFAULT_GOLANG_FLAGS) CGO_CPPFLAGS="$(CPPFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libusb-1.0" \
		PKG_CONFIG_PATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig" \
		go build \
		-o build/dist/ipsw \
		-tags libusb,unicorn \
		-ldflags "-s -w -X github.com/blacktop/ipsw/cmd/ipsw/cmd.AppVersion=$(IPSW_VERSION) -X github.com/blacktop/ipsw/cmd/ipsw/cmd.AppBuildTime=$(shell date -u +%Y%m%d)" \
		./cmd/ipsw
	$(INSTALL) -Dm755 $(BUILD_WORK)/ipsw/build/dist/ipsw $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ipsw
	cd $(BUILD_WORK)/ipsw && CGO_CC="$(CC_FOR_BUILD)" CGO_CFLAGS="$(CFLAGS_FOR_BUILD)" CGO_CPPFLAGS="$(CPPFLAGS_FOR_BUILD)" CGO_LDFLAGS="$(LDFLAGS_FOR_BUILD)" go build \
		-o build/dist/ipsw-host \
		./cmd/ipsw
	$(BUILD_WORK)/ipsw/build/dist/ipsw-host man $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	$(BUILD_WORK)/ipsw/build/dist/ipsw-host completion zsh > $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_ipsw
	$(BUILD_WORK)/ipsw/build/dist/ipsw-host completion bash > $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/ipsw
	$(BUILD_WORK)/ipsw/build/dist/ipsw-host completion fish > $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/ipsw.fish
	$(call AFTER_BUILD)
endif

ipsw-package: ipsw-stage
	# ipsw.mk Package Structure
	rm -rf $(BUILD_DIST)/ipsw

	# ipsw.mk Prep ipsw
	cp -a $(BUILD_STAGE)/ipsw $(BUILD_DIST)

	# ipsw.mk Sign
	$(call SIGN,ipsw,general.xml)

	# ipsw.mk Make .debs
	$(call PACK,ipsw,DEB_IPSW_V)

	# ipsw.mk Build cleanup
	rm -rf $(BUILD_DIST)/ipsw

.PHONY: ipsw ipsw-package
