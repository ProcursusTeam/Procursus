ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	 += ccache
CCACHE_VERSION := 4.1
DEB_CCACHE_V   ?= $(CCACHE_VERSION)

ccache-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/ccache/ccache/releases/download/v$(CCACHE_VERSION)/ccache-$(CCACHE_VERSION).tar.xz
	$(call EXTRACT_TAR,ccache-$(CCACHE_VERSION).tar.xz,ccache-$(CCACHE_VERSION),ccache)

ifneq ($(wildcard $(BUILD_WORK)/ccache/.build_complete),)
ccache:
	@echo "Using previously built ccache."
else
ccache: ccache-setup
	cd $(BUILD_WORK)/ccache && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DSTATE_DIR=/usr/bin \
		-DHAVE_C_SSE2=0 \
		-DHAVE_C_SSE41=0 \
		-DHAVE_AVX2=0 \
		-DHAVE_C_AVX2=0 \
		-DHAVE_C_AVX512=0 \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/bin \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		.
	+$(MAKE) -C $(BUILD_WORK)/ccache
	+$(MAKE) -C $(BUILD_WORK)/ccache install \
		DESTDIR="$(BUILD_STAGE)/ccache"
	touch $(BUILD_WORK)/ccache/.build_complete
endif

ccache-package: ccache-stage
	# ccache.mk Package Structure
	rm -rf $(BUILD_DIST)/ccache
	mkdir -p $(BUILD_DIST)/ccache

	# ccache.mk Prep ccache
	cp -a $(BUILD_STAGE)/ccache/usr $(BUILD_DIST)/ccache

	# ccache.mk Sign
	$(call SIGN,ccache,general.xml)

	# ccache.mk Make .debs
	$(call PACK,ccache,DEB_CCACHE_V)

	# ccache.mk Build cleanup
	rm -rf $(BUILD_DIST)/ccache

.PHONY: ccache ccache-package
