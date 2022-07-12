ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libverto
LIBVERTO_VERSION := 0.3.2
DEB_LIBVERTO_V   ?= $(LIBVERTO_VERSION)

libverto-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/latchset/libverto/releases/download/$(LIBVERTO_VERSION)/libverto-$(LIBVERTO_VERSION).tar.gz)
	$(call EXTRACT_TAR,libverto-$(LIBVERTO_VERSION).tar.gz,libverto-$(LIBVERTO_VERSION),libverto)

ifneq ($(wildcard $(BUILD_WORK)/libverto/.build_complete),)
libverto:
	@echo "Using previously built libverto."
else
libverto: libverto-setup glib2.0 libev libevent
	cd $(BUILD_WORK)/libverto && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libverto
	+$(MAKE) -C $(BUILD_WORK)/libverto install \
		DESTDIR=$(BUILD_STAGE)/libverto
	$(call AFTER_BUILD,copy)
endif

libverto-package: libverto-stage
	# libverto.mk Package Structure
	rm -rf $(BUILD_DIST)/libverto{{,-libevent,-libev,-glib}1,-dev}
	mkdir -p $(BUILD_DIST)/libverto{,-libevent,-libev,-glib}1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libverto-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libverto.mk Prep libverto1
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libverto.1.dylib $(BUILD_DIST)/libverto1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libverto.mk Prep libverto-libevent1
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libverto-libevent.1.dylib $(BUILD_DIST)/libverto-libevent1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libverto.mk Prep libverto-libev1
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libverto-libev.1.dylib $(BUILD_DIST)/libverto-libev1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libverto.mk Prep libverto-glib1
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libverto-glib.1.dylib $(BUILD_DIST)/libverto-glib1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libverto.mk Prep libverto-dev
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libverto.1.dylib|libverto-libevent.1.dylib|libverto-libev.1.dylib|libverto-glib.1.dylib) \
		$(BUILD_DIST)/libverto-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libverto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libverto-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libverto.mk Sign
	$(call SIGN,libverto1,general.xml)
	$(call SIGN,libverto-libevent1,general.xml)
	$(call SIGN,libverto-libev1,general.xml)
	$(call SIGN,libverto-glib1,general.xml)

	# libverto.mk Make .debs
	$(call PACK,libverto1,DEB_LIBVERTO_V)
	$(call PACK,libverto-libevent1,DEB_LIBVERTO_V)
	$(call PACK,libverto-libev1,DEB_LIBVERTO_V)
	$(call PACK,libverto-glib1,DEB_LIBVERTO_V)
	$(call PACK,libverto-dev,DEB_LIBVERTO_V)

	# libverto.mk Build cleanup
	rm -rf $(BUILD_DIST)/libverto{{,-libevent,-libev,-glib}1,-dev}

.PHONY: libverto libverto-package
