ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libsnappy
LIBSNAPPY_VERSION := 1.1.9
DEB_LIBSNAPPY_V   ?= $(LIBSNAPPY_VERSION)

libsnappy-setup: setup
	$(call GITHUB_ARCHIVE,google,snappy,$(LIBSNAPPY_VERSION),$(LIBSNAPPY_VERSION),libsnappy)
	$(call EXTRACT_TAR,libsnappy-$(LIBSNAPPY_VERSION).tar.gz,snappy-$(LIBSNAPPY_VERSION),libsnappy)
	$(call DO_PATCH,libsnappy,libsnappy,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libsnappy/.build_complete),)
libsnappy:
	@echo "Using previously built libsnappy."
else
libsnappy: libsnappy-setup
	cd $(BUILD_WORK)/libsnappy && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DBUILD_SHARED_LIBS=true \
		-DSNAPPY_BUILD_BENCHMARKS=false \
		-DSNAPPY_BUILD_TESTS=false
	+$(MAKE) -C $(BUILD_WORK)/libsnappy all
	+$(MAKE) -C $(BUILD_WORK)/libsnappy install \
		DESTDIR="$(BUILD_STAGE)/libsnappy"
	+$(MAKE) -C $(BUILD_WORK)/libsnappy install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libsnappy/.build_complete
endif

libsnappy-package: libsnappy-stage
	# libsnappy.mk Package Structure
	rm -rf $(BUILD_DIST)/libsnappy{1v5,-dev}
	mkdir -p $(BUILD_DIST)/libsnappy{1v5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	rm -rf $(BUILD_STAGE)/libsnappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/lib

	# libsnappy.mk Prep libsnappy-dev
	cp -a $(BUILD_STAGE)/libsnappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libsnappy.1*.dylib) $(BUILD_DIST)/libsnappy-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsnappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsnappy-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsnappy.mk Prep libsnappy1v5
	cp -a $(BUILD_STAGE)/libsnappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy.1*.dylib $(BUILD_DIST)/libsnappy1v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib


	# libsnappy.mk Sign
	$(call SIGN,libsnappy1v5,general.xml)
	$(call SIGN,libsnappy-dev,general.xml)


	# libsnappy.mk Make .debs
	$(call PACK,libsnappy1v5,DEB_LIBSNAPPY_V)
	$(call PACK,libsnappy-dev,DEB_LIBSNAPPY_V)

	# libsnappy.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsnappy{1v5,-dev}

.PHONY: libsnappy libsnappy-package
