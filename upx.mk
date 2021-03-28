ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += upx
UPX_VERSION := 3.96
DEB_UPX_V   ?= $(UPX_VERSION)

upx-setup: setup
	wget -O $(BUILD_SOURCE)/upx-$(UPX_VERSION).tar.gz https://github.com/upx/upx/archive/refs/tags/v$(UPX_VERSION).tar.gz
	wget -O $(BUILD_SOURCE)/upx-lzma-sdk-$(UPX_VERSION).tar.gz https://github.com/upx/upx-lzma-sdk/archive/refs/tags/v$(UPX_VERSION).tar.gz
	$(call EXTRACT_TAR,upx-$(UPX_VERSION).tar.gz,upx-$(UPX_VERSION),upx)
	rm -rf $(BUILD_WORK)/upx/src/lzma-sdk
	$(call EXTRACT_TAR,upx-lzma-sdk-$(UPX_VERSION).tar.gz,upx-lzma-sdk-$(UPX_VERSION),upx/src/lzma-sdk/)


ifneq ($(wildcard $(BUILD_WORK)/upx/.build_complete),)
upx:
	@echo "Using previously built upx"
else
upx: upx-setup ucl
	cd $(BUILD_WORK)/upx && PATH="$(BUILD_WORK)/upx/workaround:$(PATH)" make \
		CHECK_WHITESPACE="$(shell which true)" \
		UPX_LZMA_VERSION=0x465 \
		all

	+$(MAKE) -C $(BUILD_WORK)/upx all

	$(GINSTALL) -Dm755 $(BUILD_WORK)/upx/src/upx.out $(BUILD_STAGE)/upx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/upx-ucl
	$(GINSTALL) -Dm644 $(BUILD_WORK)/upx/doc/upx.1 $(BUILD_STAGE)/upx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/upx-ucl.1

	touch $(BUILD_WORK)/upx/.build_complete
endif

upx-package: upx-stage
	# upx.mk Package Structure
	rm -rf $(BUILD_DIST)/upx-ucl
	mkdir -p $(BUILD_DIST)/upx-ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share}

	# upx.mk Prep upx-ucl
	cp -a $(BUILD_STAGE)/upx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/upx-ucl $(BUILD_DIST)/upx-ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/upx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/upx-ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# upx.mk Sign
	$(call SIGN,upx-ucl,general.xml)

	# upx.mk Make .debs
	$(call PACK,upx-ucl,DEB_UPX_V)

	# upx.mk Build cleanup
	rm -rf $(BUILD_DIST)/upx-ucl

.PHONY: upx upx-package
