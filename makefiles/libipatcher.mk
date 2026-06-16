ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libipatcher
LIBIPATCHER_VERSION := 88
LIBIPATCHER_COMMIT  := 1e855d70c84419014e363bdbcaead7b145fe3e1f
DEB_LIBIPATCHER_V   ?= $(LIBIPATCHER_VERSION)

libipatcher-setup: setup
	$(call GITHUB_ARCHIVE,Cryptiiiic,libipatcher,$(LIBIPATCHER_COMMIT),$(LIBIPATCHER_COMMIT))
	$(call EXTRACT_TAR,libipatcher-$(LIBIPATCHER_COMMIT).tar.gz,libipatcher-$(LIBIPATCHER_COMMIT),libipatcher)

	$(call GITHUB_ARCHIVE,tihmstar,iBoot32Patcher,master,master)
	$(call GITHUB_ARCHIVE,tihmstar,jssy,master,master)
	rm -rf $(BUILD_WORK)/libipatcher/external/{jssy,iBoot32Patcher}
	$(call EXTRACT_TAR,jssy-master.tar.gz,jssy-master,libipatcher/external/jssy)
	$(call EXTRACT_TAR,iBoot32Patcher-master.tar.gz,iBoot32Patcher-master,libipatcher/external/iBoot32Patcher)

	sed -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/libipatcher/configure.ac
	sed -i '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/libipatcher/configure.ac
	sed -i 's|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/local/lib/|$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib|g' $(BUILD_WORK)/libipatcher/libipatcher/Makefile.am
	sed -i 's/git rev\-list \-\-count HEAD/printf ${LIBIPATCHER_VERSION}/g' $(BUILD_WORK)/libipatcher/configure.ac
	sed -i 's/git rev\-parse HEAD/printf ${LIBIPATCHER_COMMIT}/g' $(BUILD_WORK)/libipatcher/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libipatcher/.build_complete),)
libipatcher:
	@echo "Using previously built libipatcher."
else
libipatcher: libipatcher-setup libpng16 openssl img4tool liboffsetfinder64 libgeneral libplist curl xpwn
	cd $(BUILD_WORK)/libipatcher && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn" \
		CPPFLAGS="$(CPPFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn" \
		LDFLAGS="$(LDFLAGS) -L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xpwn"
	+$(MAKE) -C $(BUILD_WORK)/libipatcher \
		LIBS="-lcurl"
	+$(MAKE) -C $(BUILD_WORK)/libipatcher install \
		DESTDIR="$(BUILD_STAGE)/libipatcher"
	$(call AFTER_BUILD,copy)
endif

libipatcher-package: libipatcher-stage
	# libipatcher.mk Package Structure
	rm -rf $(BUILD_DIST)/libipatcher{0,-dev}
	mkdir -p $(BUILD_DIST)/libipatcher{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libipatcher.mk Prep libipatcher0
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libipatcher.0.dylib $(BUILD_DIST)/libipatcher0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libipatcher.mk Prep libipatcher-dev
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libipatcher.0.dylib) $(BUILD_DIST)/libipatcher-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libipatcher-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libipatcher.mk Sign
	$(call SIGN,libipatcher0,general.xml)

	# libipatcher.mk Make .debs
	$(call PACK,libipatcher0,DEB_LIBIPATCHER_V)
	$(call PACK,libipatcher-dev,DEB_LIBIPATCHER_V)

	# libipatcher.mk Build cleanup
	rm -rf $(BUILD_DIST)/libipatcher{0,-dev}

.PHONY: libipatcher libipatcher-package
