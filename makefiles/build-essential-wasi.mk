ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += build-essential-wasi
WASI_VERSION := 12
DEB_WASI_V   ?= $(WASI_VERSION)

build-essential-wasi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$(WASI_VERSION)/wasi-sysroot-$(WASI_VERSION).0.tar.gz
	$(call EXTRACT_TAR,wasi-sysroot-$(WASI_VERSION).0.tar.gz,wasi-sysroot,build-essential-wasi)

ifneq ($(wildcard $(BUILD_WORK)/build-essential-wasi/.build_complete),)
build-essential-wasi:
	@echo "Using previously built build-essential-wasi."
else
build-essential-wasi: build-essential-wasi-setup
	mkdir -p $(BUILD_STAGE)/build-essential-wasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WASI.sdk
	cp -a $(BUILD_WORK)/build-essential-wasi/* $(BUILD_STAGE)/build-essential-wasi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/SDKs/WASI.sdk
	touch $(BUILD_WORK)/build-essential-wasi/.build_complete
endif

build-essential-wasi-package: build-essential-wasi-stage
	# build-essential-wasi.mk Package Structure
	rm -rf $(BUILD_DIST)/build-essential-wasi

	# build-essential-wasi.mk Prep build-essential-wasi
	cp -a $(BUILD_STAGE)/build-essential-wasi $(BUILD_DIST)

	# build-essential-wasi.mk Make .debs
	$(call PACK,build-essential-wasi,DEB_WASI_V)

	# build-essential-wasi.mk Build cleanup
	rm -rf $(BUILD_DIST)/build-essential-wasi

.PHONY: build-essential-wasi build-essential-wasi-package
