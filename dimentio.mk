ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += dimentio
DIMENTIO_VERSION   := 1.0.1
DEB_DIMENTIO_V     ?= $(DIMENTIO_VERSION)

dimentio-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/dimentio-v$(DIMENTIO_VERSION).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/dimentio-v$(DIMENTIO_VERSION).tar.gz \
			https://github.com/ProcursusTeam/dimentio/archive/v$(DIMENTIO_VERSION).tar.gz
	$(call EXTRACT_TAR,dimentio-v$(DIMENTIO_VERSION).tar.gz,dimentio-$(DIMENTIO_VERSION),dimentio)

	# I'm a dumbass here. Fix this next tag.
	$(SED) -i 's/SOVERSION := 1/SOVERSION := 0/' $(BUILD_WORK)/dimentio/Makefile

	mkdir -p $(BUILD_STAGE)/dimentio/usr/{bin,lib,include}

ifneq ($(wildcard $(BUILD_WORK)/dimentio/.build_complete),)
dimentio:
	@echo "Using previously built dimentio."
else
dimentio: dimentio-setup
	+$(MAKE) -C $(BUILD_WORK)/dimentio \
		CFLAGS="$(CFLAGS) -D__arm64e__"
	cp -a $(BUILD_WORK)/dimentio/dimentio $(BUILD_STAGE)/dimentio/usr/bin
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_STAGE)/dimentio/usr/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_BASE)/usr/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_STAGE)/dimentio/usr/include
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_BASE)/usr/include
	touch $(BUILD_WORK)/dimentio/.build_complete
endif

dimentio-package: dimentio-stage
	# dimentio.mk Package Structure
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{0,-dev}
	mkdir -p $(BUILD_DIST)/dimentio/usr/bin \
		$(BUILD_DIST)/libdimentio0/usr/lib \
		$(BUILD_DIST)/libdimentio-dev/usr/{lib,include}
	
	# dimentio.mk Prep libdimentio0
	cp -a $(BUILD_STAGE)/dimentio/usr/lib/libdimentio.0.dylib $(BUILD_DIST)/libdimentio0/usr/lib

	# dimentio.mk Prep libdimentio-dev
	cp -a $(BUILD_STAGE)/dimentio/usr/lib/libdimentio.a $(BUILD_DIST)/libdimentio-dev/usr/lib
	cp -a $(BUILD_STAGE)/dimentio/usr/include/libdimentio.h $(BUILD_DIST)/libdimentio-dev/usr/include
	ln -s libdimentio.0.dylib $(BUILD_DIST)/libdimentio-dev/usr/lib/libdimentio.dylib
	
	# dimentio.mk Prep dimentio
	cp -a $(BUILD_STAGE)/dimentio/usr/bin/dimentio $(BUILD_DIST)/dimentio/usr/bin
	
	# dimentio.mk Sign
	$(call SIGN,dimentio,dimentio.xml)
	$(call SIGN,libdimentio0,dimentio.xml)
	
	# dimentio.mk Make .debs
	$(call PACK,dimentio,DEB_DIMENTIO_V)
	$(call PACK,libdimentio0,DEB_DIMENTIO_V)
	$(call PACK,libdimentio-dev,DEB_DIMENTIO_V)
	
	# dimentio.mk Build cleanup
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{0,-dev}

.PHONY: dimentio dimentio-package
