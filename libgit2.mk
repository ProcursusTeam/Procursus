ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libgit2
LIBGIT2_VERSION  := 1.1.0
DEB_LIBGIT2_V    ?= $(LIBGIT2_VERSION)

libgit2-setup: setup
	$(call GITHUB_ARCHIVE,libgit2,libgit2,$(LIBGIT2_VERSION),v$(LIBGIT2_VERSION))
	$(call EXTRACT_TAR,libgit2-$(LIBGIT2_VERSION).tar.gz,libgit2-$(LIBGIT2_VERSION),libgit2)

ifneq ($(wildcard $(BUILD_WORK)/libgit2/.build_complete),)
libgit2:
	@echo "Using previously built libgit2."
else
libgit2: libgit2-setup openssl libssh2 pcre2
	cd $(BUILD_WORK)/libgit2 && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
		-DCMAKE_CXX_FLAGS="-isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/include $(PLATFORM_VERSION_MIN) -I $(BUILD_WORK)/tapi/src/llvm/projects/clang/include -I $(BUILD_WORK)/tapi/build/projects/clang/include" \
		-DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_MODULE_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_SHARED_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_STATIC_LINKER_FLAGS="" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DREGEX_BACKEND=pcre2
	+$(MAKE) -C $(BUILD_WORK)/libgit2
	+$(MAKE) -C $(BUILD_WORK)/libgit2 install \
		DESTDIR="$(BUILD_STAGE)/libgit2"
	+$(MAKE) -C $(BUILD_WORK)/libgit2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgit2/.build_complete
endif

libgit2-package: libgit2-stage
	# libgit2.mk Package Structure
	rm -rf $(BUILD_DIST)/libgit2-{1.1,dev}
	mkdir -p $(BUILD_DIST)/libgit2-{1.1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgit2.mk Prep libgit2-1.1
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgit2.1.1*.dylib $(BUILD_DIST)/libgit2-1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgit2.mk Prep libgit2-dev
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgit2.dylib,pkgconfig} $(BUILD_DIST)/libgit2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgit2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgit2.mk Sign
	$(call SIGN,libgit2-1.1,general.xml)

	# libgit2.mk Make .debs
	$(call PACK,libgit2-1.1,DEB_LIBGIT2_V)
	$(call PACK,libgit2-dev,DEB_LIBGIT2_V)

	# libgit2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgit2-{1.1,dev}

.PHONY: libgit2 libgit2-package
