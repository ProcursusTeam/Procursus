ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += hwloc
HWLOC_V_MAJOR := 2.6
HWLOC_VERSION := $(HWLOC_V_MAJOR).0
DEB_HWLOC_V   ?= $(HWLOC_VERSION)

hwloc-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.open-mpi.org/release/hwloc/v$(HWLOC_V_MAJOR)/hwloc-$(HWLOC_VERSION).tar.bz2
	$(call EXTRACT_TAR,hwloc-$(HWLOC_VERSION).tar.bz2,hwloc-$(HWLOC_VERSION),hwloc)

ifneq ($(wildcard $(BUILD_WORK)/hwloc/.build_complete),)
hwloc:
	@echo "Using previously built hwloc."
else
hwloc: hwloc-setup cairo libx11 libice libsm ncurses
	cd $(BUILD_WORK)/hwloc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/hwloc
	+$(MAKE) -C $(BUILD_WORK)/hwloc install \
		DESTDIR=$(BUILD_STAGE)/hwloc
	+$(MAKE) -C $(BUILD_WORK)/hwloc install \
		DESTDIR=$(BUILD_BASE)
	$(call AFTER_BUILD)
endif

hwloc-package: hwloc-stage
	# hwloc.mk Package Structure
	rm -rf $(BUILD_DIST)/hwloc
	mkdir -p $(BUILD_DIST)/{hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share},libhwloc{15,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib} \
		$(BUILD_DIST)/libhwloc{-doc,-common}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/

	# hwloc.mk Prep libhwloc15
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libhwloc.15.dylib $(BUILD_DIST)/libhwloc15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# hwloc.mk Prep libhwloc-dev
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libhwloc.{a,dylib},pkgconfig} $(BUILD_DIST)/libhwloc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libhwloc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# hwloc.mk Prep libhwloc-doc
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{doc,man} $(BUILD_DIST)/libhwloc-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/

	# hwloc.mk Prep libhwloc-common
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/hwloc $(BUILD_DIST)/libhwloc-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/

	# hwloc.mk Prep hwloc
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{applications,bash-completion} $(BUILD_DIST)/hwloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/

	# hwloc.mk Sign
	$(call SIGN,libhwloc15,general.xml)
	$(call SIGN,hwloc,general.xml)

	# hwloc.mk Make .debs
	$(call PACK,libhwloc15,DEB_HWLOC_V)
	$(call PACK,libhwloc-dev,DEB_HWLOC_V)
	$(call PACK,libhwloc-doc,DEB_HWLOC_V)
	$(call PACK,libhwloc-common,DEB_HWLOC_V)
	$(call PACK,hwloc,DEB_HWLOC_V)

	# hwloc.mk Build cleanup
	rm -rf $(BUILD_DIST)/{hwloc,libhwloc{15,-dev,-doc,-common}}

.PHONY: hwloc hwloc-package
