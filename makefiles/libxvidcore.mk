ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libxvidcore
LIBXVIDCORE_VERSION := 1.3.7
DEB_LIBXVIDCORE_V   ?= $(LIBXVIDCORE_VERSION)

libxvidcore-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.xvid.com/downloads/xvidcore-$(LIBXVIDCORE_VERSION).tar.bz2
	$(call EXTRACT_TAR,xvidcore-$(LIBXVIDCORE_VERSION).tar.bz2,xvidcore,libxvidcore)

ifneq ($(wildcard $(BUILD_WORK)/libxvidcore/.build_complete),)
libxvidcore:
	@echo "Using previously built libxvidcore."
else
libxvidcore: libxvidcore-setup
	cd $(BUILD_WORK)/libxvidcore/build/generic && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxvidcore/build/generic
	+$(MAKE) -C $(BUILD_WORK)/libxvidcore/build/generic install \
		DESTDIR=$(BUILD_STAGE)/libxvidcore
	+$(MAKE) -C $(BUILD_WORK)/libxvidcore/build/generic install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libxvidcore/.build_complete
endif

libxvidcore-package: libxvidcore-stage
	# libxvidcore.mk Package Structure
	rm -rf $(BUILD_DIST)/libxvidcore{4,-dev}
	mkdir -p $(BUILD_DIST)/libxvidcore{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxvidcore.mk Prep libxvidcore4
	cp -a $(BUILD_STAGE)/libxvidcore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxvidcore.4.dylib $(BUILD_DIST)/libxvidcore4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxvidcore.mk Prep liblibxvidcore-dev
	cp -a $(BUILD_STAGE)/libxvidcore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxvidcore.a $(BUILD_DIST)/libxvidcore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxvidcore/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxvidcore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxvidcore.mk Sign
	$(call SIGN,libxvidcore4,general.xml)

	# libxvidcore.mk Make .debs
	$(call PACK,libxvidcore4,DEB_LIBXVIDCORE_V)
	$(call PACK,libxvidcore-dev,DEB_LIBXVIDCORE_V)

	# libxvidcore.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxvidcore{4,-dev}

.PHONY: libxvidcore libxvidcore-package
