ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += xpwn
XPWN_COMMIT  := def39d6e0ed0fdec0a0ff526bd11bec15d8de4e7
XPWN_VERSION := 0.5.8+git20201206.$(shell echo $(XPWN_COMMIT) | cut -c -7)
DEB_XPWN_V   ?= $(XPWN_VERSION)

xpwn-setup: setup
	$(call GITHUB_ARCHIVE,OothecaPickle,xpwn,$(XPWN_COMMIT),$(XPWN_COMMIT))
	$(call EXTRACT_TAR,xpwn-$(XPWN_COMMIT).tar.gz,xpwn-$(XPWN_COMMIT),xpwn)
	$(call DO_PATCH,xpwn,xpwn,-p1)

	$(SED) -i 's/powerpc-apple-darwin8-libtool/libtool/' $(BUILD_WORK)/xpwn/ipsw-patch/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/xpwn/.build_complete),)
xpwn:
	@echo "Using previously built xpwn."
else
xpwn: xpwn-setup libpng16 openssl
	cd $(BUILD_WORK)/xpwn && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBZIP2_LIBRARIES="-L$(TARGET_SYSROOT)/usr/lib -lbz2" \
		-DZLIB_LIBRARY="-L$(TARGET_SYSROOT)/usr/lib -lz"
	+$(MAKE) -C $(BUILD_WORK)/xpwn
	+$(MAKE) -C $(BUILD_WORK)/xpwn install \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/xpwn install \
		DESTDIR=$(BUILD_STAGE)/xpwn
	mkdir -p {$(BUILD_BASE),$(BUILD_STAGE)/xpwn}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/xpwn,lib/xpwn}
	cp -a $(BUILD_WORK)/xpwn/includes/* $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn
	cp -a $(BUILD_WORK)/xpwn/includes/* $(BUILD_STAGE)/xpwn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn
	cp -a $(BUILD_WORK)/xpwn/{ipsw-patch/libxpwn,minizip/libminizip,common/libcommon,hfs/libhfs,dmg/libdmg}.a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xpwn
	cp -a $(BUILD_WORK)/xpwn/{ipsw-patch/libxpwn,minizip/libminizip,common/libcommon,hfs/libhfs,dmg/libdmg}.a $(BUILD_STAGE)/xpwn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xpwn
	touch $(BUILD_WORK)/xpwn/.build_complete
endif

xpwn-package: xpwn-stage
	# xpwn.mk Package Structure
	rm -rf $(BUILD_DIST)/{libxpwn-dev,xpwn}
	mkdir -p $(BUILD_DIST)/{libxpwn-dev,xpwn}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xpwn.mk Prep xpwn
	cp -a $(BUILD_STAGE)/xpwn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/xpwn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xpwn.mk Prep libxpwn-dev
	cp -a $(BUILD_STAGE)/xpwn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} $(BUILD_DIST)/libxpwn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# xpwn.mk Sign
	$(call SIGN,xpwn,general.xml)

	# xpwn.mk Make .debs
	$(call PACK,xpwn,DEB_XPWN_V)
	$(call PACK,libxpwn-dev,DEB_XPWN_V)

	# xpwn.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libxpwn-dev,xpwn}

.PHONY: xpwn xpwn-package
