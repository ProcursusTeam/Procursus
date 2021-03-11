ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxtst
LIBXTST_VERSION := 1.2.3
DEB_LIBXTST_V   ?= $(LIBXTST_VERSION)

libxtst-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXtst-$(LIBXTST_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXtst-$(LIBXTST_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXtst-$(LIBXTST_VERSION).tar.gz,libXtst-$(LIBXTST_VERSION),libxtst)

ifneq ($(wildcard $(BUILD_WORK)/libxtst/.build_complete),)
libxtst:
	@echo "Using previously built libxtst."
else
libxtst: libxtst-setup xorgproto libx11 libxi
	cd $(BUILD_WORK)/libxtst && ./configure -C \
		--build=$(BUILD_MISC)/config.guess \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var
	+$(MAKE) -C $(BUILD_WORK)/libxtst
	+$(MAKE) -C $(BUILD_WORK)/libxtst install \
		DESTDIR=$(BUILD_STAGE)/libxtst
	+$(MAKE) -C $(BUILD_WORK)/libxtst install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxtst/.build_complete
endif

libxtst-package: libxtst-stage
	# libxtst.mk Package Structure
	rm -rf $(BUILD_DIST)/libxtst{6,-dev,-doc}
	mkdir -p $(BUILD_DIST)/libxtst6/usr/lib \
		$(BUILD_DIST)/libxtst-dev/usr/lib \
		$(BUILD_DIST)/libxtst-doc/usr
	
	# libxtst.mk Prep libxtst6
	cp -a $(BUILD_STAGE)/libxtst/usr/lib/libXtst.6.dylib $(BUILD_DIST)/libxtst6/usr/lib
	
	# libxtst.mk Prep libxtst-dev
	cp -a $(BUILD_STAGE)/libxtst/usr/lib/{libXtst{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxtst-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxtst/usr/include $(BUILD_DIST)/libxtst-dev/usr
	
	# libxtst.mk Prep libxtst-doc
	cp -a $(BUILD_STAGE)/libxtst/usr/share $(BUILD_DIST)/libxtst-doc/usr
	
	# libxtst.mk Sign
	$(call SIGN,libxtst6,general.xml)
	
	# libxtst.mk Make .debs
	$(call PACK,libxtst6,DEB_LIBXTST_V)
	$(call PACK,libxtst-dev,DEB_LIBXTST_V)
	$(call PACK,libxtst-doc,DEB_LIBXTST_V)
	
	# libxtst.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxtst{6,-dev,-doc}

.PHONY: libxtst libxtst-package
