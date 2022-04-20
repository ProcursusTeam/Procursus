ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tbb
TBB_VERSION_MINOR := 5
TBB_VERSION := 2021.$(TBB_VERSION_MINOR).0
DEB_TBB_V   ?= $(TBB_VERSION)

tbb-setup: setup
	$(call GITHUB_ARCHIVE,oneapi-src,oneTBB,$(TBB_VERSION),v$(TBB_VERSION))
	$(call EXTRACT_TAR,oneTBB-$(TBB_VERSION).tar.gz,oneTBB-$(TBB_VERSION),tbb)
	mkdir -p $(BUILD_WORK)/tbb/build

ifneq ($(wildcard $(BUILD_WORK)/tbb/.build_complete),)
tbb:
	@echo "Using previously built tbb."
else
tbb: tbb-setup
	cd $(BUILD_WORK)/tbb/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DTBB_TEST=OFF \
		-DTBB4PY_BUILD=OFF \
		..
	# Not seeing Debian provides oneTBB Python binding, disable it here but I'm not sure anyway
	+$(MAKE) -C $(BUILD_WORK)/tbb/build
	+$(MAKE) -C $(BUILD_WORK)/tbb/build install \
		DESTDIR="$(BUILD_STAGE)/tbb"
	$(call AFTER_BUILD)
endif

tbb-package: tbb-stage
	# tbb.mk Package Structure
	rm -rf $(BUILD_DIST)/libtbb{12,-dev}
	mkdir -p $(BUILD_DIST)/libtbb{12,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tbb.mk Prep libtbb12
	cp -a $(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtbb{.12,malloc{,_proxy}.2}{,.$(TBB_VERSION_MINOR)}.dylib $(BUILD_DIST)/libtbb12/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tbb.mk Prep libtbb-dev
	cp -a $(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtbb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake $(BUILD_DIST)/libtbb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtbb{,malloc{,_proxy}}.dylib $(BUILD_DIST)/libtbb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tbb.mk Sign
	$(call SIGN,libtbb12,general.xml)

	# tbb.mk Make .debs
	$(call PACK,libtbb12,DEB_TBB_V)
	$(call PACK,libtbb-dev,DEB_TBB_V)

	# tbb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtbb{12,-dev}

.PHONY: tbb tbb-package
