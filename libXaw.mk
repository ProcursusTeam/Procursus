ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libXaw
LIBXAW_VERSION := 1.0.13
DEB_lLIBXAW_V   ?= $(LIBXAW_VERSION)

libXaw-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXaw-$(LIBXAW_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXaw-$(LIBXAW_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXaw-$(LIBXAW_VERSION).tar.gz,libXaw-$(LIBXAW_VERSION),libXaw)

ifneq ($(wildcard $(BUILD_WORK)/libXaw/.build_complete),)
libXaw:
	@echo "Using previously built libXaw."
else
libXaw: libXaw-setup libx11 libxau libxmu xorgproto libxpm
	cd $(BUILD_WORK)/libXaw && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var
	+$(MAKE) -C $(BUILD_WORK)/libXaw
	+$(MAKE) -C $(BUILD_WORK)/libXaw install \
		DESTDIR=$(BUILD_STAGE)/libXaw
	+$(MAKE) -C $(BUILD_WORK)/libXaw install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libXaw/.build_complete
endif

libXaw-package: libXaw-stage
# libXaw.mk Package Structure
	rm -rf $(BUILD_DIST)/libXaw
	
# libXaw.mk Prep libXaw
	cp -a $(BUILD_STAGE)/libXaw $(BUILD_DIST)
	
# libXaw.mk Sign
	$(call SIGN,libXaw,general.xml)
	
# libXaw.mk Make .debs
	$(call PACK,libXaw,DEB_LIBXAW_V)
	
# libXaw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libXaw

.PHONY: libXaw libXaw-package