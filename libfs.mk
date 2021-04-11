ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libfs
LIBFS_VERSION := 1.0.8
DEB_LIBFS_V   ?= $(LIBFS_VERSION)

libfs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libFS-$(LIBFS_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libFS-$(LIBFS_VERSION).tar.gz)
	$(call EXTRACT_TAR,libFS-$(LIBFS_VERSION).tar.gz,libFS-$(LIBFS_VERSION),libfs)

ifneq ($(wildcard $(BUILD_WORK)/libfs/.build_complete),)
libfs:
	@echo "Using previously built libfs."
else
libfs: libfs-setup xorgproto xtrans
	cd $(BUILD_WORK)/libfs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libfs
	+$(MAKE) -C $(BUILD_WORK)/libfs install \
		DESTDIR=$(BUILD_STAGE)/libfs
	+$(MAKE) -C $(BUILD_WORK)/libfs install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libfs/.build_complete
endif

libfs-package: libfs-stage
	# libfs.mk Package Structure
	rm -rf $(BUILD_DIST)/libfs{6,-dev}
	mkdir -p $(BUILD_DIST)/libfs6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libfs.mk Prep libfs6
	cp -a $(BUILD_STAGE)/libfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libFS.6.dylib $(BUILD_DIST)/libfs6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libfs.mk Prep libfs-dev
	cp -a $(BUILD_STAGE)/libfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libFS.6.dylib) $(BUILD_DIST)/libfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libfs.mk Sign
	$(call SIGN,libfs6,general.xml)

	# libfs.mk Make .debs
	$(call PACK,libfs6,DEB_LIBFS_V)
	$(call PACK,libfs-dev,DEB_LIBFS_V)

	# libfs.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfs{6,-dev}

.PHONY: libfs libfs-package
