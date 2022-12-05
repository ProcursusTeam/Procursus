ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += rsync
RSYNC_VERSION := 3.2.4
DEB_RSYNC_V   ?= $(RSYNC_VERSION)-1

rsync-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://download.samba.org/pub/rsync/src/rsync-$(RSYNC_VERSION).tar.gz{$(comma).asc})
	$(call PGP_VERIFY,rsync-$(RSYNC_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,rsync-$(RSYNC_VERSION).tar.gz,rsync-$(RSYNC_VERSION),rsync)
	$(call DO_PATCH,rsync,rsync,-p1)

ifneq ($(wildcard $(BUILD_WORK)/rsync/.build_complete),)
rsync:
	@echo "Using previously built rsync."
else
rsync: rsync-setup openssl lz4 zstd xxhash popt
	cd $(BUILD_WORK)/rsync && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-included-zlib=no \
		--with-included-popt=no \
		--disable-md5-asm \
		--with-rrsync \
		--enable-ipv6 \
		--disable-simd \
		rsync_cv_HAVE_C99_VSNPRINTF=yes \
		rsync_cv_HAVE_GETTIMEOFDAY_TZ=yes
	+$(MAKE) -C $(BUILD_WORK)/rsync install \
		DESTDIR=$(BUILD_STAGE)/rsync
	$(call AFTER_BUILD)
endif

rsync-package: rsync-stage
	# rsync.mk Package Structure
	rm -rf $(BUILD_DIST)/rsync

	# rsync.mk Prep rsync
	cp -a $(BUILD_STAGE)/rsync $(BUILD_DIST)

	# rsync.mk Sign
	$(call SIGN,rsync,general.xml)

	# rsync.mk Make .debs
	$(call PACK,rsync,DEB_RSYNC_V)

	# rsync.mk Build cleanup
	rm -rf $(BUILD_DIST)/rsync

.PHONY: rsync rsync-package
