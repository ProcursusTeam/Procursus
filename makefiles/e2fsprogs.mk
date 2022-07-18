ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += e2fsprogs
E2FSPROGS_VERSION := 1.46.5
DEB_E2FSPROGS_V   ?= $(E2FSPROGS_VERSION)

e2fsprogs-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v$(E2FSPROGS_VERSION)/e2fsprogs-$(E2FSPROGS_VERSION).tar.gz)
	$(call EXTRACT_TAR,e2fsprogs-$(E2FSPROGS_VERSION).tar.gz,e2fsprogs-$(E2FSPROGS_VERSION),e2fsprogs)

ifneq ($(wildcard $(BUILD_WORK)/e2fsprogs/.build_complete),)
e2fsprogs:
	@echo "Using previously built e2fsprogs."
else
e2fsprogs: e2fsprogs-setup gettext uuid
	cd $(BUILD_WORK)/e2fsprogs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-e2initrd-helper \
		--enable-bsd-shlibs \
		--disable-ubsan \
		--disable-addrsan \
		--disable-threadsan \
		--disable-e2initrd-helper \
		--disable-fsck \
		--disable-libuuid \
		--disable-uuidd \
		--enable-symlink-install \
		--disable-fuse2fs
	+$(MAKE) -C $(BUILD_WORK)/e2fsprogs
#	Deparalelize install to fix shlib install error.
	+$(MAKE) -C $(BUILD_WORK)/e2fsprogs install -j1 \
		DESTDIR=$(BUILD_STAGE)/e2fsprogs
	+$(MAKE) -C $(BUILD_WORK)/e2fsprogs install-libs -j1 \
		DESTDIR=$(BUILD_STAGE)/e2fsprogs
	$(call AFTER_BUILD,copy)
endif

e2fsprogs-package: e2fsprogs-stage
	# e2fsprogs.mk Package Structure
	rm -rf $(BUILD_DIST)/e2fsprogs{{,-libevent,-libev,-glib}1,-dev}
	mkdir -p $(BUILD_DIST)/e2fsprogs{,-libevent,-libev,-glib}1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/e2fsprogs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# e2fsprogs.mk Prep e2fsprogs1
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/e2fsprogs.1.dylib $(BUILD_DIST)/e2fsprogs1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# e2fsprogs.mk Prep e2fsprogs-libevent1
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/e2fsprogs-libevent.1.dylib $(BUILD_DIST)/e2fsprogs-libevent1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# e2fsprogs.mk Prep e2fsprogs-libev1
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/e2fsprogs-libev.1.dylib $(BUILD_DIST)/e2fsprogs-libev1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# e2fsprogs.mk Prep e2fsprogs-glib1
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/e2fsprogs-glib.1.dylib $(BUILD_DIST)/e2fsprogs-glib1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# e2fsprogs.mk Prep e2fsprogs-dev
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(e2fsprogs.1.dylib|e2fsprogs-libevent.1.dylib|e2fsprogs-libev.1.dylib|e2fsprogs-glib.1.dylib) \
		$(BUILD_DIST)/e2fsprogs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/e2fsprogs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/e2fsprogs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# e2fsprogs.mk Sign
	$(call SIGN,e2fsprogs1,general.xml)
	$(call SIGN,e2fsprogs-libevent1,general.xml)
	$(call SIGN,e2fsprogs-libev1,general.xml)
	$(call SIGN,e2fsprogs-glib1,general.xml)

	# e2fsprogs.mk Make .debs
	$(call PACK,e2fsprogs1,DEB_E2FSPROGS_V)
	$(call PACK,e2fsprogs-libevent1,DEB_E2FSPROGS_V)
	$(call PACK,e2fsprogs-libev1,DEB_E2FSPROGS_V)
	$(call PACK,e2fsprogs-glib1,DEB_E2FSPROGS_V)
	$(call PACK,e2fsprogs-dev,DEB_E2FSPROGS_V)

	# e2fsprogs.mk Build cleanup
	rm -rf $(BUILD_DIST)/e2fsprogs{{,-libevent,-libev,-glib}1,-dev}

.PHONY: e2fsprogs e2fsprogs-package
