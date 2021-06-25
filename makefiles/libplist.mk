ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libplist
LIBPLIST_VERSION  := 2.2.0
DEB_LIBPLIST_V    ?= $(LIBPLIST_VERSION)

libplist-setup: setup
	$(call GITHUB_ARCHIVE,libimobiledevice,libplist,$(LIBPLIST_VERSION),$(LIBPLIST_VERSION))
	$(call EXTRACT_TAR,libplist-$(LIBPLIST_VERSION).tar.gz,libplist-$(LIBPLIST_VERSION),libplist)

ifneq ($(wildcard $(BUILD_WORK)/libplist/.build_complete),)
libplist:
	@echo "Using previously built libplist."
else
libplist: libplist-setup
	cd $(BUILD_WORK)/libplist && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libplist
	+$(MAKE) -C $(BUILD_WORK)/libplist install \
		DESTDIR="$(BUILD_STAGE)/libplist"
	+$(MAKE) -C $(BUILD_WORK)/libplist install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libplist/.build_complete
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
