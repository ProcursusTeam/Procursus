ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libxaw
LIBXAW_VERSION := 1.0.13
DEB_lLIBXAW_V   ?= $(LIBXAW_VERSION)

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
# libxaw.mk Package Structure
	rm -rf $(BUILD_DIST)/libxaw
	
# libxaw.mk Prep libxaw
	cp -a $(BUILD_STAGE)/libxaw $(BUILD_DIST)
	
# libxaw.mk Sign
	$(call SIGN,libxaw,general.xml)
	
# libxaw.mk Make .debs
	$(call PACK,libxaw,DEB_LIBXAW_V)
	
# libxaw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxaw

.PHONY: libxaw libxaw-package
