ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	 += ccache
CCACHE_VERSION := 4.2.1
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
ccache: ccache-setup zstd
	cd $(BUILD_WORK)/ccache && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DZSTD_INCLUDE_DIR=$(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		-DZSTD_LIBRARY=$(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzstd.dylib \
		$(CCACHE_CMAKE_ARGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/ccache
	+$(MAKE) -C $(BUILD_WORK)/ccache install \
		DESTDIR="$(BUILD_STAGE)/ccache"
	mkdir -p $(BUILD_STAGE)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ccache
	touch $(BUILD_WORK)/ccache/.build_complete
endif

ccache-package: ccache-stage
	# ccache.mk Package Structure
	rm -rf $(BUILD_DIST)/ccache
	mkdir -p $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1,libexec/ccache}
	for compiler in clang clang++ cc gcc gcc2 gcc3 gcc-3.3 gcc-4.0 gcc-4.2 gcc-4.3 gcc-4.4 gcc-4.5 gcc-4.6 gcc-4.7 gcc-4.8 \
		gcc-4.9 gcc-5 gcc-6 gcc-7 gcc-8 gcc-9 gcc-10 c++ c++3 c++-3.3 c++-4.0 c++-4.2 c++-4.3 c++-4.4 c++-4.5 c++-4.6 \
		c++-4.7 c++-4.8 c++-4.9 c++-5 c++-6 c++-7 c++-8 c++-9 c++-10 g++ g++2 g++3 g++-3.3 g++-4.0 g++-4.2 g++-4.3 g++-4.4 \
		g++-4.5 g++-4.6 g++-4.7 g++-4.8 g++-4.9 g++-5 g++-6 g++-7 g++-8 g++-9 g++-10 ; do \
  			ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ccache $(BUILD_DIST)/ccache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ccache/$$compiler ; \
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

