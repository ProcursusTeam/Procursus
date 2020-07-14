ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libarchive
LIBARCHIVE_VERSION := 3.4.3
DEB_LIBARCHIVE_V   ?= $(LIBARCHIVE_VERSION)

libarchive-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libarchive/libarchive/releases/download/v$(LIBARCHIVE_VERSION)/libarchive-$(LIBARCHIVE_VERSION).tar.xz
	$(call EXTRACT_TAR,libarchive-$(LIBARCHIVE_VERSION).tar.xz,libarchive-$(LIBARCHIVE_VERSION),libarchive)

ifneq ($(wildcard $(BUILD_WORK)/libarchive/.build_complete),)
libarchive:
	@echo "Using previously built libarchive."
else
libarchive: libarchive-setup lz4 zstd xz
	cd $(BUILD_WORK)/libarchive && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--disable-dependency-tracking \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libarchive
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_STAGE)/libarchive"
	+$(MAKE) -C $(BUILD_WORK)/libarchive install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libarchive/.build_complete
endif

libarchive-package: libarchive-stage
	# rsync.mk Package Structure
	rm -rf $(BUILD_DIST)/libarchive
	mkdir -p $(BUILD_DIST)/libarchive
	
	# rsync.mk Prep rsync
	cp -a $(BUILD_STAGE)/libarchive/usr $(BUILD_DIST)/libarchive
	
	# rsync.mk Sign
	$(call SIGN,libarchive,general.xml)
	
	# rsync.mk Make .debs
	$(call PACK,libarchive,DEB_LIBARCHIVE_V)
	
	# rsync.mk Build cleanup
	rm -rf $(BUILD_DIST)/libarchive

.PHONY: libarchive libarchive-package
