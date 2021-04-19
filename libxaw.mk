ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxaw
LIBXAW_VERSION := 1.0.13
DEB_lLIBXAW_V  ?= $(LIBXAW_VERSION)

libxaw-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXaw-$(LIBXAW_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXaw-$(LIBXAW_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXaw-$(LIBXAW_VERSION).tar.gz,libXaw-$(LIBXAW_VERSION),libxaw)

ifneq ($(wildcard $(BUILD_WORK)/libxaw/.build_complete),)
libxaw:
	@echo "Using previously built libxaw."
else
libxaw: libxaw-setup libx11 libxau libxmu xorgproto libxpm libxt libxext
	cd $(BUILD_WORK)/libxaw && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxaw
	+$(MAKE) -C $(BUILD_WORK)/libxaw install \
		DESTDIR=$(BUILD_STAGE)/libxaw
	+$(MAKE) -C $(BUILD_WORK)/libxaw install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxaw/.build_complete
endif

libxaw-package: libxaw-stage
# libxau.mk Package Structure
	rm -rf $(BUILD_DIST)/libxaw{7,-dev}
	mkdir -p $(BUILD_DIST)/libxaw7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxaw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib,share}

	# libxaw.mk Prep libxaw7
	cp -a $(BUILD_STAGE)/libxaw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXaw{.6,.7,6,7,7.7,6.6}.dylib $(BUILD_DIST)/libxaw7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxaw.mk Prep libxaw-dev
	cp -a $(BUILD_STAGE)/libxaw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXaw{7.a,6.a,.dylib},pkgconfig} $(BUILD_DIST)/libxaw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxaw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxaw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxaw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libxaw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxaw.mk Sign
	$(call SIGN,libxaw7,general.xml)

	# libxaw.mk Make .debs
	$(call PACK,libxaw7,DEB_LIBXAW_V)
	$(call PACK,libxaw-dev,DEB_LIBXAW_V)

	# libxaw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxaw{7,-dev}

.PHONY: libxaw libxaw-package
