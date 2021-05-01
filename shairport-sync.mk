ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += shairport-sync
SHAIRPORT-SYNC_VERSION := 3.3.8
DEB_SHAIRPORT-SYNC_V   ?= $(SHAIRPORT-SYNC_VERSION)

shairport-sync-setup: setup
	$(call GITHUB_ARCHIVE,mikebrady,shairport-sync,$(SHAIRPORT-SYNC_VERSION),$(SHAIRPORT-SYNC_VERSION))
	$(call EXTRACT_TAR,shairport-sync-$(SHAIRPORT-SYNC_VERSION).tar.gz,shairport-sync-$(SHAIRPORT-SYNC_VERSION),shairport-sync)

ifneq ($(wildcard $(BUILD_WORK)/shairport-sync/.build_complete),)
shairport-sync:
	@echo "Using previously built shairport-sync."
else
shairport-sync: shairport-sync-setup openssl libsoundio libao libsoxr popt libconfig alac
	cd $(BUILD_WORK)/shairport-sync && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-os=darwin \
		--with-dummy \
		--with-stdout \
		--with-pipe \
		--with-configfiles \
		--with-apple-alac \
		--with-ssl=openssl \
		--with-soxr \
		--with-metadata \
		--with-ao \
		--with-soundio \
		--with-dns_sd
	+$(MAKE) -C $(BUILD_WORK)/shairport-sync
	+$(MAKE) -C $(BUILD_WORK)/shairport-sync install \
		DESTDIR=$(BUILD_STAGE)/shairport-sync

	mkdir -p $(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_MISC)/shairport-sync/*.plist $(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)/Library/LaunchDaemons

	mkdir -p $(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_MISC)/shairport-sync/shairport-sync-wrapper $(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	for file in $(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)/Library/LaunchDaemons/* \
		$(BUILD_STAGE)/shairport-sync/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
			$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $$file; \
			$(SED) -i 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $$file; \
	done

	touch $(BUILD_WORK)/shairport-sync/.build_complete
endif

shairport-sync-package: shairport-sync-stage
	# shairport-sync.mk Package Structure
	rm -rf $(BUILD_DIST)/shairport-sync
	mkdir -p $(BUILD_DIST)/shairport-sync

	# shairport-sync.mk Prep shairport-sync
	cp -a $(BUILD_STAGE)/shairport-sync $(BUILD_DIST)

	# shairport-sync.mk Sign
	$(call SIGN,shairport-sync,audio.xml)

	# shairport-sync.mk Make .debs
	$(call PACK,shairport-sync,DEB_SHAIRPORT-SYNC_V)

	# shairport-sync.mk Build cleanup
	rm -rf $(BUILD_DIST)/shairport-sync

.PHONY: shairport-sync shairport-sync-package
