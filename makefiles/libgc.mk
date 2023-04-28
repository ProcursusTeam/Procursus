ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libgc
LIBGC_VERSION   := 8.2.2
LIBATOMIC_OPS_V := 7.6.14
DEB_LIBGC_V     ?= $(LIBGC_VERSION)

libgc-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.hboehm.info/gc/gc_source/{gc-$(LIBGC_VERSION)$(comma)libatomic_ops-$(LIBATOMIC_OPS_V)}.tar.gz)
	$(call EXTRACT_TAR,gc-$(LIBGC_VERSION).tar.gz,gc-$(LIBGC_VERSION),libgc)
	$(call EXTRACT_TAR,libatomic_ops-$(LIBATOMIC_OPS_V).tar.gz,libatomic_ops-$(LIBATOMIC_OPS_V),libgc/libatomic_ops)

ifneq ($(wildcard $(BUILD_WORK)/libgc/.build_complete),)
libgc:
	@echo "Using previously built libgc."
else
libgc: libgc-setup
	cd $(BUILD_WORK)/libgc/libatomic_ops && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libgc/libatomic_ops
	cd $(BUILD_WORK)/libgc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-cplusplus \
		--enable-large-config
	+$(MAKE) -C $(BUILD_WORK)/libgc
	+$(MAKE) -C $(BUILD_WORK)/libgc install \
		DESTDIR="$(BUILD_STAGE)/libgc"
	$(call AFTER_BUILD)
endif

libgc-package: libgc-stage
	# libgc.mk Package Structure
	rm -rf $(BUILD_DIST)/{libgc-dev,libgc1}
	mkdir -p $(BUILD_DIST)/{libgc-dev,libgc1}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgc.mk Prep libgc-dev
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libgc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcord,libgc,libgccpp,libgctba}.a \
		$(BUILD_DIST)/libgc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libgc.mk Prep libgc1
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgc{,.1}.dylib $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcord{,.1}.dylib $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgccpp{,.1}.dylib $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgctba{,.1}.dylib $(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/libgc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcord,libgc,libgccpp,libgctba}.la \
		$(BUILD_DIST)/libgc1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libgc.mk Sign
	$(call SIGN,libgc1,general.xml)
	$(call SIGN,libgc-dev,general.xml)

	# libgc.mk Make .debs
	$(call PACK,libgc1,DEB_LIBGC_V)
	$(call PACK,libgc-dev,DEB_LIBGC_V)

	# libgc.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libgc-dev,libgc1}

.PHONY: libgc libgc-package
