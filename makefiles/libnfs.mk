ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libnfs
LIBNFS_VERSION := 5.0.2
DEB_LIBNFS_V   ?= $(LIBNFS_VERSION)

libnfs-setup: setup
	$(call GITHUB_ARCHIVE,sahlberg,libnfs,$(LIBNFS_VERSION),libnfs-$(LIBNFS_VERSION))
	$(call EXTRACT_TAR,libnfs-$(LIBNFS_VERSION).tar.gz,libnfs-libnfs-$(LIBNFS_VERSION),libnfs)

ifneq ($(wildcard $(BUILD_WORK)/libnfs/.build_complete),)
libnfs:
	@echo "Using previously built libnfs."
else
libnfs: libnfs-setup
	cd $(BUILD_WORK)/libnfs && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-utils \
		--enable-pthread \
		--disable-examples \
		--disable-werror
	+$(MAKE) -C $(BUILD_WORK)/libnfs
	+$(MAKE) -C $(BUILD_WORK)/libnfs install \
		DESTDIR="$(BUILD_STAGE)/libnfs"
	$(call AFTER_BUILD,copy)
endif

libnfs-package: libnfs-stage
	# libnfs.mk Package Structure
	rm -rf $(BUILD_DIST)/libnfs{14,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libnfs{14,-dev,-utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libnfs{14,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libnfs.mk Prep libnfs14
	cp -a $(BUILD_STAGE)/libnfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnfs.14.dylib $(BUILD_DIST)/libnfs14/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libnfs.mk Prep libnfs-dev
	cp -a $(BUILD_STAGE)/libnfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libnfs.{dylib,a},pkgconfig} $(BUILD_DIST)/libnfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libnfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libnfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libnfs.mk Prep libnfs-utils
	cp -a $(BUILD_STAGE)/libnfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libnfs-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libnfs.mk Sign
	$(call SIGN,libnfs14,general.xml)
	$(call SIGN,libnfs-utils,general.xml)

	# libnfs.mk Make .debs
	$(call PACK,libnfs14,DEB_LIBNFS_V)
	$(call PACK,libnfs-dev,DEB_LIBNFS_V)
	$(call PACK,libnfs-utils,DEB_LIBNFS_V)

	# libnfs.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnfs{14,-dev,-utils}

.PHONY: libnfs libnfs-package
