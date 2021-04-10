ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libXres
LIBXRES_VERSION := 1.2.1
DEB_LIBXRES_V   ?= $(XRES_VERSION)

libXres-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXres-$(LIBXRES_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXres-$(LIBXRES_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXres-$(LIBXRES_VERSION).tar.gz,libXres-$(LIBXRES_VERSION),libXres)

ifneq ($(wildcard $(BUILD_WORK)/libXres/.build_complete),)
libXres:
	@echo "Using previously built libXres."
else
libXres: libXres-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/libXres && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var
	+$(MAKE) -C $(BUILD_WORK)/libXres
	+$(MAKE) -C $(BUILD_WORK)/libXres install \
		DESTDIR=$(BUILD_STAGE)/libXres
	+$(MAKE) -C $(BUILD_WORK)/libXres install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libXres/.build_complete
endif

libXres-package: libXres-stage
# libXres.mk Package Structure
	rm -rf $(BUILD_DIST)/libXres
	
# libXres.mk Prep libXres
	cp -a $(BUILD_STAGE)/libXres $(BUILD_DIST)
	
# libXres.mk Sign
	$(call SIGN,libXres,general.xml)
	
# libXres.mk Make .debs
	$(call PACK,libXres,DEB_XRES_V)
	
# libXres.mk Build cleanup
	rm -rf $(BUILD_DIST)/libXres

.PHONY: libXres libXres-package