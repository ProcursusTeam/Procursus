ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += liboffsetfinder64
LIBOFFSETFINDER64_VERSION := 126
DEB_LIBOFFSETFINDER64_V   ?= $(LIBOFFSETFINDER64_VERSION)

liboffsetfinder64-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/liboffsetfinder64-$(LIBOFFSETFINDER64_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/liboffsetfinder64-$(LIBOFFSETFINDER64_VERSION).tar.gz \
			https://github.com/tihmstar/liboffsetfinder64/archive/$(LIBOFFSETFINDER64_VERSION).tar.gz
	$(call EXTRACT_TAR,liboffsetfinder64-$(LIBOFFSETFINDER64_VERSION).tar.gz,liboffsetfinder64-$(LIBOFFSETFINDER64_VERSION),liboffsetfinder64)

ifneq ($(wildcard $(BUILD_WORK)/liboffsetfinder64/.build_complete),)
liboffsetfinder64:
	@echo "Using previously built liboffsetfinder64."
else
liboffsetfinder64: liboffsetfinder64-setup libgeneral libinsn img4tool openssl
	cd $(BUILD_WORK)/liboffsetfinder64 && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/liboffsetfinder64
	+$(MAKE) -C $(BUILD_WORK)/liboffsetfinder64 install \
		DESTDIR="$(BUILD_STAGE)/liboffsetfinder64"
	+$(MAKE) -C $(BUILD_WORK)/liboffsetfinder64 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/liboffsetfinder64/.build_complete
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
