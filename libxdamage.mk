ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxdamage
LIBXDAMAGE_VERSION := 1.1.5
DEB_LIBXDAMAGE_V   ?= $(LIBXDAMAGE_VERSION)

libxdamage-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXdamage-$(LIBXDAMAGE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXdamage-$(LIBXDAMAGE_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXdamage-$(LIBXDAMAGE_VERSION).tar.gz,libXdamage-$(LIBXDAMAGE_VERSION),libxdamage)

ifneq ($(wildcard $(BUILD_WORK)/libxdamage/.build_complete),)
libxdamage:
	@echo "Using previously built libxdamage."
else
libxdamage: libxdamage-setup xorgproto libx11 libxfixes
	cd $(BUILD_WORK)/libxdamage && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var
	+$(MAKE) -C $(BUILD_WORK)/libxdamage
	+$(MAKE) -C $(BUILD_WORK)/libxdamage install \
		DESTDIR=$(BUILD_STAGE)/libxdamage
	+$(MAKE) -C $(BUILD_WORK)/libxdamage install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxdamage/.build_complete
endif

libxdamage-package: libxdamage-stage
	# libxdamage.mk Package Structure
	rm -rf $(BUILD_DIST)/libxdamage{1,-dev}
	mkdir -p $(BUILD_DIST)/libxdamage1/usr/lib \
		$(BUILD_DIST)/libxdamage-dev/usr/{include,lib}
	
	# libxdamage.mk Prep libxdamage1
	cp -a $(BUILD_STAGE)/libxdamage/usr/lib/libXdamage.1.dylib $(BUILD_DIST)/libxdamage1/usr/lib

	# libxdamage.mk Prep libxdamage-dev
	cp -a $(BUILD_STAGE)/libxdamage/usr/lib/!(libXdamage.1.dylib) $(BUILD_DIST)/libxdamage-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxdamage/usr/include $(BUILD_DIST)/libxdamage-dev/usr
	
	# libxdamage.mk Sign
	$(call SIGN,libxdamage1,general.xml)
	
	# libxdamage.mk Make .debs
	$(call PACK,libxdamage1,DEB_LIBXDAMAGE_V)
	$(call PACK,libxdamage-dev,DEB_LIBXDAMAGE_V)
	
	# libxdamage.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxdamage{1,-dev}

.PHONY: libxdamage libxdamage-package
