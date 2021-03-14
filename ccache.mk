
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	 += ccache
CCACHE_VERSION := 4.2
DEB_CCACHE_V   ?= $(CCACHE_VERSION)

ifneq (,$(findstring arm64,$(MEMO_TARGET)))
CCACHE_CMAKE_ARGS := -DHAVE_NEON=TRUE \
    -DHAVE_ASM_AVX2=FALSE \
    -DHAVE_ASM_SSE2=FALSE \
    -DHAVE_ASM_SSE41=FALSE \
    -DHAVE_ASM_AVX512=FALSE
else
CCACHE_CMAKE_ARGS := -DHAVE_NEON=FALSE \
    -DHAVE_ASM_SSE2=TRUE \
    -DHAVE_ASM_SSE41=TRUE \
    -DHAVE_ASM_AVX2=TRUE \
    -DHAVE_ASM_AVX512=FALSE
endif

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
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		$(CCACHE_CMAKE_ARGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/ccache
	+$(MAKE) -C $(BUILD_WORK)/ccache install \
		DESTDIR="$(BUILD_STAGE)/ccache"
	touch $(BUILD_WORK)/ccache/.build_complete
endif

ccache-package: ccache-stage
	# ccache.mk Package Structure
	rm -rf $(BUILD_DIST)/ccache
	mkdir -p $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# ccache.mk Prep ccache
	cp -a $(BUILD_STAGE)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ccache.mk Sign
	$(call SIGN,ccache,general.xml)

	# ccache.mk Make .debs
	$(call PACK,ccache,DEB_CCACHE_V)

	# ccache.mk Build cleanup
	rm -rf $(BUILD_DIST)/ccache

.PHONY: ccache ccache-package
