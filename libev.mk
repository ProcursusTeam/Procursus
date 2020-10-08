ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libev
LIBEV_VERSION := 4.33
DEB_LIBEV_V   ?= $(LIBEV_VERSION)

libev-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://dist.schmorp.de/libev/libev-$(LIBEV_VERSION).tar.gz
	$(call EXTRACT_TAR,libev-$(LIBEV_VERSION).tar.gz,libev-$(LIBEV_VERSION),libev)

ifneq ($(wildcard $(BUILD_WORK)/libev/.build_complete),)
libev:
	@echo "Using previously built libev."
else
libev: libev-setup
	cd $(BUILD_WORK)/libev && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libev install \
		DESTDIR=$(BUILD_STAGE)/libev
	# Do not make install to build_base do to conflicts with event.h from libevent.
	cp -a $(BUILD_STAGE)/libev/usr/include/ev{,++}.h $(BUILD_BASE)/usr/include
	cp -a $(BUILD_STAGE)/libev/usr/lib/* $(BUILD_BASE)/usr/lib
	touch $(BUILD_WORK)/libev/.build_complete
endif

libev-package: libev-stage
	# libev.mk Package Structure
	rm -rf $(BUILD_DIST)/libev{4,{,-libevent}-dev}
	mkdir -p $(BUILD_DIST)/libev4/usr/lib \
		$(BUILD_DIST)/libev-dev/usr/{include,lib} \
		$(BUILD_DIST)/libev-libevent-dev/usr/include
	
	# libev.mk Prep libev4
	cp -a $(BUILD_STAGE)/libev/usr/lib/libev.4.dylib $(BUILD_DIST)/libev4/usr/lib

	# libev.mk Prep libev-dev
	cp -a $(BUILD_STAGE)/libev/usr/include/!(event.h) $(BUILD_DIST)/libev-dev/usr/include
	cp -a $(BUILD_STAGE)/libev/usr/lib/!(libev.4.dylib) $(BUILD_DIST)/libev-dev/usr/lib

	# libev.mk Prep libev-libevent-dev
	cp -a $(BUILD_STAGE)/libev/usr/include/event.h $(BUILD_DIST)/libev-libevent-dev/usr/include
	
	# libev.mk Sign
	$(call SIGN,libev4,general.xml)
	
	# libev.mk Make .debs
	$(call PACK,libev4,DEB_LIBEV_V)
	$(call PACK,libev-dev,DEB_LIBEV_V)
	$(call PACK,libev-libevent-dev,DEB_LIBEV_V)
	
	# libev.mk Build cleanup
	rm -rf $(BUILD_DIST)/libev{4,{,-libevent}-dev}

.PHONY: libev libev-package
