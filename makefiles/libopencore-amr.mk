ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += libopencore-amr
LIBOPENCORE-AMR_VERSION := 0.1.5
DEB_LIBOPENCORE-AMR_V   ?= $(LIBOPENCORE-AMR_VERSION)

libopencore-amr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-$(LIBOPENCORE-AMR_VERSION).tar.gz
	$(call EXTRACT_TAR,opencore-amr-$(LIBOPENCORE-AMR_VERSION).tar.gz,opencore-amr-$(LIBOPENCORE-AMR_VERSION),libopencore-amr)

ifneq ($(wildcard $(BUILD_WORK)/libopencore-amr/.build_complete),)
libopencore-amr:
	@echo "Using previously built libopencore-amr."
else
libopencore-amr: libopencore-amr-setup
	cd $(BUILD_WORK)/libopencore-amr && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/libopencore-amr
	+$(MAKE) -C $(BUILD_WORK)/libopencore-amr install \
		DESTDIR=$(BUILD_STAGE)/libopencore-amr
	+$(MAKE) -C $(BUILD_WORK)/libopencore-amr install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libopencore-amr/.build_complete
endif

libopencore-amr-package: libopencore-amr-stage
	# libopencore-amr.mk Package Structure
	rm -rf $(BUILD_DIST)/libopencore-amr{n,w}b{0,-dev}
	mkdir -p $(BUILD_DIST)/libopencore-amr{n,w}b{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libopencore-amr{n,w}b-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libopencore-amr.mk Prep libopencore-amrnb0
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopencore-amrnb.0.dylib $(BUILD_DIST)/libopencore-amrnb0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libopencore-amr.mk Prep libopencore-amrnb-dev
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopencore-amrnb.{dylib,a} $(BUILD_DIST)/libopencore-amrnb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/opencore-amrnb $(BUILD_DIST)/libopencore-amrnb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libopencore-amr.mk Prep libopencore-amrwb0
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopencore-amrwb.0.dylib $(BUILD_DIST)/libopencore-amrwb0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libopencore-amr.mk Prep libopencore-amrwb-dev
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopencore-amrwb.{dylib,a} $(BUILD_DIST)/libopencore-amrwb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libopencore-amr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/opencore-amrwb $(BUILD_DIST)/libopencore-amrwb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libopencore-amr.mk Sign
	$(call SIGN,libopencore-amrnb0,general.xml)
	$(call SIGN,libopencore-amrwb0,general.xml)

	# libopencore-amr.mk Make .debs
	$(call PACK,libopencore-amrnb0,DEB_LIBOPENCORE-AMR_V)
	$(call PACK,libopencore-amrnb-dev,DEB_LIBOPENCORE-AMR_V)
	$(call PACK,libopencore-amrwb0,DEB_LIBOPENCORE-AMR_V)
	$(call PACK,libopencore-amrwb-dev,DEB_LIBOPENCORE-AMR_V)

	# libopencore-amr.mk Build cleanup
	rm -rf $(BUILD_DIST)/libopencore-amr{n,w}b{0,-dev}

.PHONY: libopencore-amr libopencore-amr-package
