ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libipatcher
LIBIPATCHER_VERSION := 81
DEB_LIBIPATCHER_V   ?= $(LIBIPATCHER_VERSION)

libipatcher-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libipatcher-$(LIBIPATCHER_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libipatcher-$(LIBIPATCHER_VERSION).tar.gz \
			https://github.com/tihmstar/libipatcher/archive/$(LIBIPATCHER_VERSION).tar.gz
	$(call EXTRACT_TAR,libipatcher-$(LIBIPATCHER_VERSION).tar.gz,libipatcher-$(LIBIPATCHER_VERSION),libipatcher)

	-[ ! -f "$(BUILD_SOURCE)/iBoot32Patcher.tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/iBoot32Patcher.tar.gz \
			https://github.com/tihmstar/iBoot32Patcher/tarball/master
	-[ ! -f "$(BUILD_SOURCE)/jssy.tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/jssy.tar.gz \
			https://github.com/tihmstar/jssy/tarball/master
	rm -rf $(BUILD_WORK)/libipatcher/external/{jssy,iBoot32Patcher}
	$(call EXTRACT_TAR,jssy.tar.gz,tihmstar-jssy-*,libipatcher/external/jssy)
	$(call EXTRACT_TAR,iBoot32Patcher.tar.gz,tihmstar-iBoot32Patcher-*,libipatcher/external/iBoot32Patcher)

	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/libipatcher/configure.ac
	$(SED) -i '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/libipatcher/configure.ac
	$(SED) -i 's|/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/local/lib/|$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib|g' $(BUILD_WORK)/libipatcher/libipatcher/Makefile.am

ifneq ($(wildcard $(BUILD_WORK)/libipatcher/.build_complete),)
libipatcher:
	@echo "Using previously built libipatcher."
else
libipatcher: libipatcher-setup libpng16 openssl img4tool liboffsetfinder64 libgeneral libplist curl xpwn
	cd $(BUILD_WORK)/libipatcher && ./autogen.sh \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CFLAGS="$(CFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn" \
		CPPFLAGS="$(CPPFLAGS) -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/xpwn" \
		LDFLAGS="$(LDFLAGS) -L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xpwn"
	+$(MAKE) -C $(BUILD_WORK)/libipatcher
	+$(MAKE) -C $(BUILD_WORK)/libipatcher install \
		DESTDIR="$(BUILD_STAGE)/libipatcher"
	+$(MAKE) -C $(BUILD_WORK)/libipatcher install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libipatcher/.build_complete
endif

libipatcher-package: libipatcher-stage
	# libipatcher.mk Package Structure
	rm -rf $(BUILD_DIST)/libipatcher{0,-dev}
	mkdir -p $(BUILD_DIST)/libipatcher{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libipatcher.mk Prep libipatcher0
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libipatcher.0.dylib $(BUILD_DIST)/libipatcher0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libipatcher.mk Prep libipatcher-dev
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libipatcher.0.dylib) $(BUILD_DIST)/libipatcher-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libipatcher/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libipatcher-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libipatcher.mk Sign
	$(call SIGN,libipatcher0,general.xml)
	
	# libipatcher.mk Make .debs
	$(call PACK,libipatcher0,DEB_LIBIPATCHER_V)
	$(call PACK,libipatcher-dev,DEB_LIBIPATCHER_V)
	
	# libipatcher.mk Build cleanup
	rm -rf $(BUILD_DIST)/libipatcher{0,-dev}

.PHONY: libipatcher libipatcher-package
