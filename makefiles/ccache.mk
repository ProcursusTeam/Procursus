ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	 += ccache
CCACHE_VERSION := 4.7.4
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
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/ccache/ccache/releases/download/v$(CCACHE_VERSION)/ccache-$(CCACHE_VERSION).tar.xz)
	$(call EXTRACT_TAR,ccache-$(CCACHE_VERSION).tar.xz,ccache-$(CCACHE_VERSION),ccache)

ifneq ($(wildcard $(BUILD_WORK)/ccache/.build_complete),)
ccache:
	@echo "Using previously built ccache."
else
ccache: ccache-setup zstd
	cd $(BUILD_WORK)/ccache && unset MACOSX_DEPLOYMENT_TARGET && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DZSTD_INCLUDE_DIR=$(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		-DZSTD_LIBRARY=$(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzstd.dylib \
		$(CCACHE_CMAKE_ARGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/ccache
	+$(MAKE) -C $(BUILD_WORK)/ccache install \
		DESTDIR="$(BUILD_STAGE)/ccache"
	mkdir -p $(BUILD_STAGE)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ccache
	$(call AFTER_BUILD)
endif

ccache-package: ccache-stage
	# ccache.mk Package Structure
	rm -rf $(BUILD_DIST)/ccache
	mkdir -p $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1,libexec/ccache}
	for compiler in clang clang++ cc c++; do \
  			$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ccache $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ccache/$$compiler ; \
	done

	# ccache.mk Prep ccache
	cp -a $(BUILD_STAGE)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share,libexec} $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ccache.mk Sign
	$(call SIGN,ccache,general.xml)

	# ccache.mk Make .debs
	$(call PACK,ccache,DEB_CCACHE_V)

	# ccache.mk Build cleanup
	rm -rf $(BUILD_DIST)/ccache

.PHONY: ccache ccache-package

