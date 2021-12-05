ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += xmrig
XMRIG_VERSION := 6.15.3
DEB_XMRIG_V   ?= $(XMRIG_VERSION)

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
XMRIG_CMAKE_FLAGS := -DWITH_OPENCL=OFF -DWITH_SECURE_JIT=OFF
else
XMRIG_CMAKE_FLAGS :=
endif

xmrig-setup: setup
	$(call GITHUB_ARCHIVE,xmrig,xmrig,$(XMRIG_VERSION),v$(XMRIG_VERSION))
	$(call EXTRACT_TAR,xmrig-$(XMRIG_VERSION).tar.gz,xmrig-$(XMRIG_VERSION),xmrig)
  $(call DO_PATCH,xmrig,xmrig,-p1)
	mkdir -p $(BUILD_WORK)/xmrig/build

ifneq ($(wildcard $(BUILD_WORK)/xmrig/.build_complete),)
xmrig:
	@echo "Using previously built xmrig."
else
xmrig: xmrig-setup libuv1 openssl hwloc
	cd $(BUILD_WORK)/xmrig/build && LDFLAGS="$(LDFLAGS) -Wl,-framework,CoreFoundation" cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		$(XMRIG_CMAKE_FLAGS) \
    -DUV_LIBRARY="$(BUILD_BASE)/usr/lib/libuv.dylib" \
    -DOPENSSL_CRYPTO_LIBRARY="$(BUILD_BASE)/usr/lib/libcrypto.dylib" \
    -DOPENSSL_SSL_LIBRARY="$(BUILD_BASE)/usr/lib/libssl.dylib" \
		-DWITH_CN_GPU=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/xmrig/build
	$(call AFTER_BUILD)
endif

xmrig-package: xmrig-stage
	# xmrig.mk Package Structure
	rm -rf $(BUILD_DIST)/xmrig
	
	# xmrig.mk Prep xmrig
	cp -a $(BUILD_STAGE)/xmrig $(BUILD_DIST)
	
	# xmrig.mk Sign
	$(call SIGN,xmrig,general.xml)
	
	# xmrig.mk Make .debs
	$(call PACK,xmrig,DEB_XMRIG_V)
	
	# xmrig.mk Build cleanup
	rm -rf $(BUILD_DIST)/xmrig

.PHONY: xmrig xmrig-package
