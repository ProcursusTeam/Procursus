ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += trustcache
TRUSTCACHE_VERSION := 2.0
DEB_TRUSTCACHE_V   ?= $(TRUSTCACHE_VERSION)

trustcache-setup: setup
	$(call GITHUB_ARCHIVE,CRKatri,trustcache,$(TRUSTCACHE_VERSION),v$(TRUSTCACHE_VERSION))
	$(call EXTRACT_TAR,trustcache-$(TRUSTCACHE_VERSION).tar.gz,trustcache-$(TRUSTCACHE_VERSION),trustcache)

ifneq ($(wildcard $(BUILD_WORK)/trustcache/.build_complete),)
trustcache:
	@echo "Using previously built trustcache."
else
trustcache: trustcache-setup libmd
	+$(MAKE) -C $(BUILD_WORK)/trustcache install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/trustcache/"
	ln -s trustcache $(BUILD_STAGE)/trustcache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tc
	$(call AFTER_BUILD)
endif

trustcache-package: trustcache-stage
	# trustcache.mk Package Structure
	rm -rf $(BUILD_DIST)/trustcache

	# trustcache.mk Prep trustcache
	cp -a $(BUILD_STAGE)/trustcache $(BUILD_DIST)

	# trustcache.mk Sign
	$(call SIGN,trustcache,general.xml)

	# trustcache.mk Make .debs
	$(call PACK,trustcache,DEB_TRUSTCACHE_V)

	# trustcache.mk Build cleanup
	rm -rf $(BUILD_DIST)/trustcache

.PHONY: trustcache trustcache-package
