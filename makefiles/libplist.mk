ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libplist
LIBPLIST_COMMIT   := 4b50a5acf1e26ff44904d5e533ff0fc06bde3e61
LIBPLIST_VERSION  := 2.2.0+git20230130.$(shell echo $(LIBPLIST_COMMIT) | cut -c -7)
DEB_LIBPLIST_V    ?= $(LIBPLIST_VERSION)

libplist-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libplist,$(LIBPLIST_COMMIT),$(LIBPLIST_COMMIT))
	$(call EXTRACT_TAR,libplist-$(LIBPLIST_COMMIT).tar.gz,libplist-$(LIBPLIST_COMMIT),libplist)
	$(call DO_PATCH,libplist,libplist,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libplist/.build_complete),)
libplist:
	@echo "Using previously built libplist."
else
libplist: libplist-setup
	cd $(BUILD_WORK)/libplist && NOCONFIGURE=1 ./autogen.sh && \
		sed -i 's/-keep_private_externs -nostdlib/-keep_private_externs $(PLATFORM_VERSION_MIN) -arch $(MEMO_ARCH) -nostdlib/g' $(BUILD_WORK)/libplist/configure && \
		./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		PACKAGE_VERSION="$(LIBPLIST_VERSION)" \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libplist V=1
	+$(MAKE) -C $(BUILD_WORK)/libplist install \
		DESTDIR="$(BUILD_STAGE)/libplist"
	$(call AFTER_BUILD,copy)
endif

libplist-package: .SHELLFLAGS=-O extglob -c
libplist-package: libplist-stage
	# libplist.mk Package Structure
	rm -rf $(BUILD_DIST)/libplist{3,-dev,-utils} $(BUILD_DIST)/libplist++{3v5,-dev}
	mkdir -p $(BUILD_DIST)/libplist3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libplist-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/plist,lib/pkgconfig} \
		$(BUILD_DIST)/libplist-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libplist++3v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libplist++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/plist,lib/pkgconfig}

	# libplist.mk Prep libplist3
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libplist-2.0.3.dylib $(BUILD_DIST)/libplist3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libplist.mk Prep libplist-dev
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/plist/plist.h $(BUILD_DIST)/libplist-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/plist
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libplist-2.0.{a,dylib} $(BUILD_DIST)/libplist-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libplist-2.0.pc $(BUILD_DIST)/libplist-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libplist.mk Prep libplist-utils
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libplist-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libplist.mk Prep libplist++3v5
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libplist++-2.0.3.dylib $(BUILD_DIST)/libplist++3v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libplist.mk Prep libplist++-dev
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/plist/!(plist).h $(BUILD_DIST)/libplist++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/plist
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libplist++-2.0.{a,dylib} $(BUILD_DIST)/libplist++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libplist/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libplist++-2.0.pc $(BUILD_DIST)/libplist++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# libplist.mk Sign
	$(call SIGN,libplist3,general.xml)
	$(call SIGN,libplist-utils,general.xml)
	$(call SIGN,libplist++3v5,general.xml)

	# libplist.mk Make .debs
	$(call PACK,libplist3,DEB_LIBPLIST_V)
	$(call PACK,libplist-dev,DEB_LIBPLIST_V)
	$(call PACK,libplist-utils,DEB_LIBPLIST_V)
	$(call PACK,libplist++3v5,DEB_LIBPLIST_V)
	$(call PACK,libplist++-dev,DEB_LIBPLIST_V)

	# libplist.mk Build cleanup
	rm -rf $(BUILD_DIST)/libplist{3,-dev,-utils} $(BUILD_DIST)/libplist++{3v5,-dev}

.PHONY: libplist libplist-package
