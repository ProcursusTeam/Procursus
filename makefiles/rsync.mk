ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += rsync
RSYNC_VERSION := 3.2.3
DEB_RSYNC_V   ?= $(RSYNC_VERSION)-1

rsync-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.samba.org/pub/rsync/src/rsync-$(RSYNC_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,rsync-$(RSYNC_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,rsync-$(RSYNC_VERSION).tar.gz,rsync-$(RSYNC_VERSION),rsync)

ifneq ($(wildcard $(BUILD_WORK)/rsync/.build_complete),)
rsync:
	@echo "Using previously built rsync."
else
rsync: rsync-setup openssl lz4 zstd xxhash
	cd $(BUILD_WORK)/rsync && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-simd \
		rsync_cv_HAVE_GETTIMEOFDAY_TZ=yes
	+$(MAKE) -C $(BUILD_WORK)/rsync install \
		DESTDIR=$(BUILD_STAGE)/rsync
	touch $(BUILD_WORK)/rsync/.build_complete
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
