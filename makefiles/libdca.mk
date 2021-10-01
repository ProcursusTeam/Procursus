ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libdca
LIBDCA_VERSION := 0.0.7
DEB_LIBDCA_V   ?= $(LIBDCA_VERSION)

libdca-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdca/$(LIBDCA_VERSION)/libdca-$(LIBDCA_VERSION).tar.bz2
	$(call EXTRACT_TAR,libdca-$(LIBDCA_VERSION).tar.bz2,libdca-$(LIBDCA_VERSION),libdca)

ifneq ($(wildcard $(BUILD_WORK)/libdca/.build_complete),)
libdca:
	@echo "Using previously built libdca."
else
libdca: libdca-setup
	cd $(BUILD_WORK)/libdca && ./bootstrap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-static \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libdca
	+$(MAKE) -C $(BUILD_WORK)/libdca install \
		DESTDIR=$(BUILD_STAGE)/libdca
	$(call AFTER_BUILD,copy)
endif

libdca-package: libdca-stage
	# libdca.mk Package Structure
	rm -rf $(BUILD_DIST)/libdca{0,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libdca{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libdca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libdca.mk Prep libdca0
	cp -a $(BUILD_STAGE)/libdca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdca.0.dylib $(BUILD_DIST)/libdca0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdca.mk Prep libdca-dev
	cp -a $(BUILD_STAGE)/libdca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libdca.{dylib,a}} $(BUILD_DIST)/libdca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdca.mk Prep libdca-utils
	cp -a $(BUILD_STAGE)/libdca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libdca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libdca.mk Sign
	$(call SIGN,libdca0,general.xml)
	$(call SIGN,libdca-utils,general.xml)
	
	# libdca.mk Make .debs
	$(call PACK,libdca0,DEB_LIBDCA_V)
	$(call PACK,libdca-dev,DEB_LIBDCA_V)
	$(call PACK,libdca-utils,DEB_LIBDCA_V)
	
	# libdca.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdca{0,-dev,-utils}

.PHONY: libdca libdca-package
