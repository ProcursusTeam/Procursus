ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += liboffsetfinder64
LIBOFFSETFINDER64_VERSION := 161
LIBOFFSETFINDER64_COMMIT  := a2bdcdc70682d2c6ce214aa5dc417618a93fbcee
DEB_LIBOFFSETFINDER64_V   ?= $(LIBOFFSETFINDER64_VERSION)

liboffsetfinder64-setup: setup
	$(call GITHUB_ARCHIVE,Cryptiiiic,liboffsetfinder64,$(LIBOFFSETFINDER64_COMMIT),$(LIBOFFSETFINDER64_COMMIT))
	$(call EXTRACT_TAR,liboffsetfinder64-$(LIBOFFSETFINDER64_COMMIT).tar.gz,liboffsetfinder64-$(LIBOFFSETFINDER64_COMMIT),liboffsetfinder64)

ifneq ($(wildcard $(BUILD_WORK)/liboffsetfinder64/.build_complete),)
liboffsetfinder64:
	@echo "Using previously built liboffsetfinder64."
else
liboffsetfinder64: liboffsetfinder64-setup libgeneral libinsn img4tool openssl libplist
	cd $(BUILD_WORK)/liboffsetfinder64 && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DARCH="$(MEMO_ARCH)" \
		-DDESTDIR="$(BUILD_STAGE)/liboffsetfinder64" \
		-DVERSION_COMMIT_COUNT="$(LIBOFFSETFINDER64_VERSION)" \
		-DVERSION_COMMIT_SHA="$(LIBOFFSETFINDER64_COMMIT)" \
		-DCMAKE_INSTALL_RPATH="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
		-DNO_XCODE=1

	+$(MAKE) -C $(BUILD_WORK)/liboffsetfinder64
	+$(MAKE) -C $(BUILD_WORK)/liboffsetfinder64 install
	$(call AFTER_BUILD,copy)
endif

liboffsetfinder64-package: liboffsetfinder64-stage
	# liboffsetfinder64.mk Package Structure
	rm -rf $(BUILD_DIST)/liboffsetfinder64-{0,dev}
	mkdir -p $(BUILD_DIST)/liboffsetfinder64-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liboffsetfinder64.mk Prep liboffsetfinder64-0
	cp -a $(BUILD_STAGE)/liboffsetfinder64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liboffsetfinder64.0.dylib $(BUILD_DIST)/liboffsetfinder64-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liboffsetfinder64.mk Prep liboffsetfinder64-dev
	cp -a $(BUILD_STAGE)/liboffsetfinder64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(liboffsetfinder64.0.dylib) $(BUILD_DIST)/liboffsetfinder64-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/liboffsetfinder64/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liboffsetfinder64-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# liboffsetfinder64.mk Sign
	$(call SIGN,liboffsetfinder64-0,general.xml)

	# liboffsetfinder64.mk Make .debs
	$(call PACK,liboffsetfinder64-0,DEB_LIBOFFSETFINDER64_V)
	$(call PACK,liboffsetfinder64-dev,DEB_LIBOFFSETFINDER64_V)

	# liboffsetfinder64.mk Build cleanup
	rm -rf $(BUILD_DIST)/liboffsetfinder64-{0,dev}

.PHONY: liboffsetfinder64 liboffsetfinder64-package
