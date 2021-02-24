ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libxfixes
LIBXFIXES_VERSION := 5.0.3
DEB_LIBXFIXES_V   ?= $(LIBXFIXES_VERSION)

libxfixes-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXfixes-$(LIBXFIXES_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXfixes-$(LIBXFIXES_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXfixes-$(LIBXFIXES_VERSION).tar.gz,libXfixes-$(LIBXFIXES_VERSION),libxfixes)

ifneq ($(wildcard $(BUILD_WORK)/libxfixes/.build_complete),)
libxfixes:
	@echo "Using previously built libxfixes."
else
libxfixes: libxfixes-setup libx11 xorgproto
	cd $(BUILD_WORK)/libxfixes && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--sysconfdir=/etc \
		--localstatedir=/var
	+$(MAKE) -C $(BUILD_WORK)/libxfixes
	+$(MAKE) -C $(BUILD_WORK)/libxfixes install \
		DESTDIR=$(BUILD_STAGE)/libxfixes
	+$(MAKE) -C $(BUILD_WORK)/libxfixes install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxfixes/.build_complete
endif

libxfixes-package: libxfixes-stage
	# libxfixes.mk Package Structure
	rm -rf $(BUILD_DIST)/libxfixes{3,-dev}
	mkdir -p $(BUILD_DIST)/libxfixes3/usr/lib \
		$(BUILD_DIST)/libxfixes-dev/usr/{include,lib}
	
	# libxfixes.mk Prep libxfixes3
	cp -a $(BUILD_STAGE)/libxfixes/usr/lib/libXfixes.3.dylib $(BUILD_DIST)/libxfixes3/usr/lib

	# libxfixes.mk Prep libxfixes-dev
	cp -a $(BUILD_STAGE)/libxfixes/usr/lib/!(libXfixes.3.dylib) $(BUILD_DIST)/libxfixes-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxfixes/usr/{include,share} $(BUILD_DIST)/libxfixes-dev/usr
	
	# libxfixes.mk Sign
	$(call SIGN,libxfixes3,general.xml)
	
	# libxfixes.mk Make .debs
	$(call PACK,libxfixes3,DEB_LIBXFIXES_V)
	$(call PACK,libxfixes-dev,DEB_LIBXFIXES_V)
	
	# libxfixes.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxfixes{3,-dev}

.PHONY: libxfixes libxfixes-package