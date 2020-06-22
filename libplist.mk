ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libplist
DOWNLOAD          += https://github.com/libimobiledevice/libplist/archive/$(LIBPLIST_VERSION).tar.gz
LIBPLIST_VERSION  := 2.2.0
DEB_LIBPLIST_V    ?= $(LIBPLIST_VERSION)

libplist-setup: setup
	$(call EXTRACT_TAR,$(LIBPLIST_VERSION).tar.gz,libplist-$(LIBPLIST_VERSION),libplist)

ifneq ($(wildcard $(BUILD_WORK)/libplist/.build_complete),)
libplist:
	@echo "Using previously built libplist."
else
libplist: libplist-setup
	cd $(BUILD_WORK)/libplist && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-cython
	+$(MAKE) -C $(BUILD_WORK)/libplist
	+$(MAKE) -C $(BUILD_WORK)/libplist install \
		DESTDIR="$(BUILD_STAGE)/libplist"
	+$(MAKE) -C $(BUILD_WORK)/libplist install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libplist/.build_complete
endif

libplist-package: libplist-stage
	# libplist.mk Package Structure
	rm -rf $(BUILD_DIST)/libplist

	# libplist.mk Prep libplist
	cp -a $(BUILD_STAGE)/libplist $(BUILD_DIST)

	# libplist.mk Sign
	$(call SIGN,libplist,general.xml)

	# libplist.mk Make .debs
	$(call PACK,libplist,DEB_LIBPLIST_V)

	# libplist.mk Build cleanup
	rm -rf $(BUILD_DIST)/libplist

.PHONY: libplist libplist-package
