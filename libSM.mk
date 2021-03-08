ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libsm
LIBSM_VERSION := 1.2.3
DEB_LIBSM_V   ?= $(LIBSM_VERSION)

libsm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libSM-$(LIBSM_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libSM-$(LIBSM_VERSION).tar.gz)
	$(call EXTRACT_TAR,libSM-$(LIBSM_VERSION).tar.gz,libSM-$(LIBSM_VERSION),libsm)

ifneq ($(wildcard $(BUILD_WORK)/libsm/.build_complete),)
libsm:
	@echo "Using previously built libsm."
else
libsm: libsm-setup xtrans libice uuid
	cd $(BUILD_WORK)/libsm && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--enable-malloc0returnsnull=no \
		--enable-docs=no
	+$(MAKE) -C $(BUILD_WORK)/libsm
	+$(MAKE) -C $(BUILD_WORK)/libsm install \
		DESTDIR=$(BUILD_STAGE)/libsm
	+$(MAKE) -C $(BUILD_WORK)/libsm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsm/.build_complete
endif

libsm-package: libsm-stage
	# libsm.mk Package Structure
	rm -rf $(BUILD_DIST)/libsm{6,-dev}
	mkdir -p $(BUILD_DIST)/libsm6/usr/lib \
		$(BUILD_DIST)/libsm-dev/usr/{include,lib}
	
	# libsm.mk Prep libsm6
	cp -a $(BUILD_STAGE)/libsm/usr/lib/libSM.6.dylib $(BUILD_DIST)/libsm6/usr/lib

	# libsm.mk Prep libsm-dev
	cp -a $(BUILD_STAGE)/libsm/usr/lib/!(libSM.6.dylib) $(BUILD_DIST)/libsm-dev/usr/lib
	cp -a $(BUILD_STAGE)/libsm/usr/include $(BUILD_DIST)/libsm-dev/usr
	
	# libsm.mk Sign
	$(call SIGN,libsm6,general.xml)
	
	# libsm.mk Make .debs
	$(call PACK,libsm6,DEB_LIBSM_V)
	$(call PACK,libsm-dev,DEB_LIBSM_V)
	
	# libsm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsm{6,-dev}

.PHONY: libsm libsm-package
