ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libgit2
LIBGIT2_VERSION  := 1.5.0
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
		-DUSE_SSH=ON \
		-DUSE_HTTPS=OpenSSL \
		-DUSE_SHA1=HTTPS \
		-DUSE_SHA256=HTTPS \
		-DREGEX_BACKEND=pcre2 \
		-DBUILD_CLI=dynamic \
		-DBUILD_TESTS=OFF
	+$(MAKE) -C $(BUILD_WORK)/libgit2
	+$(MAKE) -C $(BUILD_WORK)/libgit2 install \
		DESTDIR="$(BUILD_STAGE)/libgit2"
	$(call AFTER_BUILD,copy)
endif

libgit2-package: libgit2-stage
	# libgit2.mk Package Structure
	rm -rf $(BUILD_DIST)/libgit2-{1.5,cli,dev}
	mkdir -p $(BUILD_DIST)/libgit2-{1.5,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgit2-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libgit2.mk Prep libgit2-1.5
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgit2.1.5*.dylib $(BUILD_DIST)/libgit2-1.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgit2.mk Prep libgit2-dev
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgit2.dylib,pkgconfig} $(BUILD_DIST)/libgit2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgit2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgit2.mk Prep libgit2-cli
	cp -a $(BUILD_STAGE)/libgit2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/git2_cli $(BUILD_DIST)/libgit2-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libgit2.mk Sign
	$(call SIGN,libgit2-1.5,general.xml)
	$(call SIGN,libgit2-cli,general.xml)

	# libgit2.mk Make .debs
	$(call PACK,libgit2-1.5,DEB_LIBGIT2_V)
	$(call PACK,libgit2-dev,DEB_LIBGIT2_V)
	$(call PACK,libgit2-cli,DEB_LIBGIT2_V)

	# libgit2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgit2-{1.5,cli,dev}

.PHONY: libgit2 libgit2-package
