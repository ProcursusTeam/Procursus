ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libinsn
LIBINSN_VERSION := 35
DEB_LIBINSN_V   ?= $(LIBINSN_VERSION)

libinsn-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libinsn-$(LIBINSN_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libinsn-$(LIBINSN_VERSION).tar.gz \
			https://github.com/tihmstar/libinsn/archive/$(LIBINSN_VERSION).tar.gz
	$(call EXTRACT_TAR,libinsn-$(LIBINSN_VERSION).tar.gz,libinsn-$(LIBINSN_VERSION),libinsn)

ifneq ($(wildcard $(BUILD_WORK)/libinsn/.build_complete),)
libinsn:
	@echo "Using previously built libinsn."
else
libinsn: libinsn-setup libgeneral
	cd $(BUILD_WORK)/libinsn && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr 
	+$(MAKE) -C $(BUILD_WORK)/libinsn
	+$(MAKE) -C $(BUILD_WORK)/libinsn install \
		DESTDIR="$(BUILD_STAGE)/libinsn"
	+$(MAKE) -C $(BUILD_WORK)/libinsn install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libinsn/.build_complete
endif

libinsn-package: libinsn-stage
	# libinsn.mk Package Structure
	rm -rf $(BUILD_DIST)/libinsn{0,-dev}
	mkdir -p $(BUILD_DIST)/libinsn{0,-dev}/usr/lib
	
	# libinsn.mk Prep libinsn0
	cp -a $(BUILD_STAGE)/libinsn/usr/lib/libinsn.0.dylib $(BUILD_DIST)/libinsn0/usr/lib
	
	# libinsn.mk Prep libinsn-dev
	cp -a $(BUILD_STAGE)/libinsn/usr/lib/!(libinsn.0.dylib) $(BUILD_DIST)/libinsn-dev/usr/lib
	cp -a $(BUILD_STAGE)/libinsn/usr/include $(BUILD_DIST)/libinsn-dev/usr
	
	# libinsn.mk Sign
	$(call SIGN,libinsn0,general.xml)
	
	# libinsn.mk Make .debs
	$(call PACK,libinsn0,DEB_LIBINSN_V)
	$(call PACK,libinsn-dev,DEB_LIBINSN_V)
	
	# libinsn.mk Build cleanup
	rm -rf $(BUILD_DIST)/libinsn{0,-dev}

.PHONY: libinsn libinsn-package
