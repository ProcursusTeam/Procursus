ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxres
LIBXRES_VERSION := 1.2.1
DEB_LIBXRES_V   ?= $(XRES_VERSION)

libxres-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXres-$(LIBXRES_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXres-$(LIBXRES_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXres-$(LIBXRES_VERSION).tar.gz,libXres-$(LIBXRES_VERSION),libxres)

ifneq ($(wildcard $(BUILD_WORK)/libxres/.build_complete),)
libxres:
	@echo "Using previously built libxres."
else
libxres: libxres-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/libxres && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxres
	+$(MAKE) -C $(BUILD_WORK)/libxres install \
		DESTDIR=$(BUILD_STAGE)/libxres
	+$(MAKE) -C $(BUILD_WORK)/libxres install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxres/.build_complete
endif

libxres-package: libxres-stage
# libxres.mk Package Structure
	rm -rf $(BUILD_DIST)/libxres
	
# libxres.mk Prep libxres
	cp -a $(BUILD_STAGE)/libxres $(BUILD_DIST)
	
# libxres.mk Sign
	$(call SIGN,libxres,general.xml)
	
# libxres.mk Make .debs
	$(call PACK,libxres,DEB_XRES_V)
	
# libxres.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxres

.PHONY: libxres libxres-package
