ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxcursor
LIBXCURSOR_VERSION := 1.2.0
DEB_LIBXCURSOR_V   ?= $(LIBXCURSOR_VERSION)

libxcursor-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXcursor-$(LIBXCURSOR_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXcursor-$(LIBXCURSOR_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXcursor-$(LIBXCURSOR_VERSION).tar.bz2,libXcursor-$(LIBXCURSOR_VERSION),libXcursor)

ifneq ($(wildcard $(BUILD_WORK)/libxcursor/.build_complete),)
libxcursor:
	@echo "Using previously built libxcursor."
else
libxcursor: libxcursor-setup libx11 libxfixes libxrender util-macros
	cd $(BUILD_WORK)/libxcursor && unset CPP CPPFLAGS && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var
	+$(MAKE) -C $(BUILD_WORK)/libxcursor
	+$(MAKE) -C $(BUILD_WORK)/libxcursor install \
		DESTDIR=$(BUILD_STAGE)/libxcursor
	+$(MAKE) -C $(BUILD_WORK)/libxcursor install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxcursor/.build_complete
endif

libxcursor-package: libxcursor-stage
	# libxcursor.mk Package Structure
	rm -rf $(BUILD_DIST)/libxcursor{1,-dev}
	mkdir -p $(BUILD_DIST)/libxcursor1/usr/lib \
		$(BUILD_DIST)/libxcursor-dev/usr/lib \
		$(BUILD_DIST)/libxcursor1/usr/lib
	
	# libxcursor.mk Prep libxcursor1
	cp -a $(BUILD_STAGE)/libxcursor/usr/lib/libXcursor.1.dylib $(BUILD_DIST)/libxcursor1/usr/lib

	# libxcursor.mk Prep libxcursor-dev
	cp -a $(BUILD_STAGE)/libxcursor/usr/lib/!(libXcursor.1.dylib) $(BUILD_DIST)/libxcursor-dev/usr/lib
	cp -a $(BUILD_STAGE)/libxcursor/usr/{include,share} $(BUILD_DIST)/libxcursor-dev/usr
	
	# libxcursor.mk Sign
	$(call SIGN,libxcursor1,general.xml)

	# libxcursor.mk Make .debs
	$(call PACK,libxcursor1,DEB_LIBXCURSOR_V)
	$(call PACK,libxcursor-dev,DEB_LIBXCURSOR_V)
	
	# libxcursor.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxcursor{1,-dev}

.PHONY: libxcursor libxcursor-package
