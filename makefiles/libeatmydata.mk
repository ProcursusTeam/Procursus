ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libeatmydata
LIBEATMYDATA_VERSION := 130
DEB_LIBEATMYDATA_V   ?= $(LIBEATMYDATA_VERSION)

libeatmydata-setup: setup
	$(call GITHUB_ARCHIVE,stewartsmith,libeatmydata,$(LIBEATMYDATA_VERSION),v$(LIBEATMYDATA_VERSION))
	$(call EXTRACT_TAR,libeatmydata-$(LIBEATMYDATA_VERSION).tar.gz,libeatmydata-$(LIBEATMYDATA_VERSION),libeatmydata)

ifneq ($(wildcard $(BUILD_WORK)/libeatmydata/.build_complete),)
libeatmydata:
	@echo "Using previously built libeatmydata."
else
libeatmydata: libeatmydata-setup
	cd $(BUILD_WORK)/libeatmydata && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libeatmydata
	+$(MAKE) -C $(BUILD_WORK)/libeatmydata install \
		DESTDIR=$(BUILD_STAGE)/libeatmydata
	# Don't copy to build_base otherwise it will lib-EAT-everyone's-DATA
	$(call AFTER_BUILD)
endif

libeatmydata-package: libeatmydata-stage
	# libeatmydata.mk Package Structure
	rm -rf $(BUILD_DIST)/{eatmydata,libeatmydata1}
	mkdir -p $(BUILD_DIST)/libeatmydata1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/eatmydata/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libeatmydata.mk Prep libeatmydata1
	cp -a $(BUILD_STAGE)/libeatmydata/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libeatmydata.dylib $(BUILD_DIST)/libeatmydata1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libeatmydata.1.dylib
	$(LN_SR) $(BUILD_DIST)/libeatmydata1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libeatmydata.{1.,}dylib
	# nothing should be linking this so no -dev package
	
	# libeatmydata.mk Prep eatmydata
	cp -a $(BUILD_STAGE)/libeatmydata/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec} $(BUILD_DIST)/eatmydata/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libeatmydata.mk Sign
	$(call SIGN,libeatmydata1,general.xml)
	$(call SIGN,eatmydata,general.xml)
	
	# libeatmydata.mk Make .debs
	$(call PACK,eatmydata,DEB_LIBEATMYDATA_V)
	$(call PACK,libeatmydata1,DEB_LIBEATMYDATA_V)
	
	# libeatmydata.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libeatmydata1,eatmydata}

.PHONY: libeatmydata libeatmydata-package
