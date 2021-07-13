ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libdvbcsa
LIBDVBCSA_VERSION := 1.1.0
DEB_LIBDVBCSA_V   ?= $(LIBDVBCSA_VERSION)

libdvbcsa-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libdvbcsa/$(LIBDVBCSA_VERSION)/libdvbcsa-$(LIBDVBCSA_VERSION).tar.gz
	$(call EXTRACT_TAR,libdvbcsa-$(LIBDVBCSA_VERSION).tar.gz,libdvbcsa-$(LIBDVBCSA_VERSION),libdvbcsa)
	echo "echo $(GNU_HOST_TRIPLE)" > $(BUILD_WORK)/libdvbcsa/config.sub

ifneq ($(wildcard $(BUILD_WORK)/libdvbcsa/.build_complete),)
libdvbcsa:
	@echo "Using previously built libdvbcsa."
else
libdvbcsa: libdvbcsa-setup
	cd $(BUILD_WORK)/libdvbcsa && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-static \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libdvbcsa
	+$(MAKE) -C $(BUILD_WORK)/libdvbcsa install \
		DESTDIR=$(BUILD_STAGE)/libdvbcsa
	+$(MAKE) -C $(BUILD_WORK)/libdvbcsa install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libdvbcsa/.build_complete
endif

libdvbcsa-package: libdvbcsa-stage
	# libdvbcsa.mk Package Structure
	rm -rf $(BUILD_DIST)/libdvbcsa{1,-dev}
	mkdir -p $(BUILD_DIST)/libdvbcsa{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvbcsa.mk Prep libdvbcsa1
	cp -a $(BUILD_STAGE)/libdvbcsa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvbcsa.1.dylib $(BUILD_DIST)/libdvbcsa1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvbcsa.mk Prep libdvbcsa-dev
	cp -a $(BUILD_STAGE)/libdvbcsa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdvbcsa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libdvbcsa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdvbcsa.{dylib,a} $(BUILD_DIST)/libdvbcsa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libdvbcsa.mk Sign
	$(call SIGN,libdvbcsa1,general.xml)
	
	# libdvbcsa.mk Make .debs
	$(call PACK,libdvbcsa1,DEB_LIBDVBCSA_V)
	$(call PACK,libdvbcsa-dev,DEB_LIBDVBCSA_V)
	
	# libdvbcsa.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdvbcsa{1,-dev}

.PHONY: libdvbcsa libdvbcsa-package
