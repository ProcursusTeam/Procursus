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
	rm -r $(BUILD_WORK)/upx/src/lzma-sdk
	$(call EXTRACT_TAR,upx-lzma-sdk-$(UPX_VERSION).tar.gz,upx-lzma-sdk-$(UPX_VERSION),upx/src/lzma-sdk/)


ifneq ($(wildcard $(BUILD_WORK)/upx/.build_complete),)
upx:
	@echo "Using previously built upx"
else
PATH := $(BUILD_WORK)/upx/workaround:$(PATH)
upx: upx-setup ucl
	cd $(BUILD_WORK)/upx && make \
		CHECK_WHITESPACE=/usr/bin/true \
		UPX_LZMA_VERSION=0x465 \
		all
		
	+$(MAKE) -C $(BUILD_WORK)/upx all

	$(GINSTALL) -Dm755 $(BUILD_WORK)/upx/src/upx.out $(BUILD_STAGE)/upx/usr/bin/upx
	$(GINSTALL) -Dm644 $(BUILD_WORK)/upx/doc/upx.1 $(BUILD_STAGE)/upx/usr/share/man/man1/upx.1

	touch $(BUILD_WORK)/upx/.build_complete
endif

upx-package: upx-stage
	# upx.mk Package Structure
	rm -rf $(BUILD_DIST)/upx
	mkdir -p $(BUILD_DIST)/upx/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{bin,share}
		
	# upx.mk Prep upx-dev
	cp -a $(BUILD_STAGE)/upx/usr/bin/upx $(BUILD_DIST)/upx/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/upx/usr/share/man $(BUILD_DIST)/upx/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share
	
	# upx.mk Sign
	$(call SIGN,upx,general.xml)
	
	# upx.mk Make .debs
	$(call PACK,upx,DEB_UPX_V)
	
	# upx.mk Build cleanup
	rm -rf $(BUILD_DIST)/upx

.PHONY: upx upx-package
