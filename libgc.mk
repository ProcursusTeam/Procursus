ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libgc
LIBGC_VERSION := 8.0.4
DEB_LIBGC_V   ?= $(LIBGC_VERSION)

libgc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.hboehm.info/gc/gc_source/gc-$(LIBGC_VERSION).tar.gz
	$(call EXTRACT_TAR,gc-$(LIBGC_VERSION).tar.gz,gc-$(LIBGC_VERSION),libgc)

ifneq ($(wildcard $(BUILD_WORK)/libgc/.build_complete),)
libgc:
	@echo "Using previously built libgc."
else
libgc: libgc-setup libatomic_ops

	cd $(BUILD_WORK)/libgc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-shared=yes \
		--enable-static=no
	+$(MAKE) -C $(BUILD_WORK)/libgc
	+$(MAKE) -C $(BUILD_WORK)/libgc install \
		DESTDIR=$(BUILD_STAGE)/libgc
	+$(MAKE) -C $(BUILD_WORK)/libgc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgc/.build_complete
endif

libgc-package: libgc-stage
	# libgc.mk Package Structure
	rm -rf $(BUILD_DIST)/libgc{1,-dev}
	mkdir -p $(BUILD_DIST)/libgc{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgc.mk Prep libgc1
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcord.1.dylib,libgc.1.dylib} $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgc.mk Prep libgc-dev
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcord.dylib,libgc.dylib,pkgconfig} $(BUILD_DIST)/libgc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgc.mk Sign
	$(call SIGN,libgc1,general.xml)

	# libgc.mk Make .debs
	$(call PACK,libgc1,DEB_LIBGC_V)
	$(call PACK,libgc-dev,DEB_LIBGC_V)

	# libgc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgc{1,-dev}

.PHONY: libgc libgc-package
