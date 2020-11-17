ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += dimentio
DIMENTIO_VERSION   := 1.0.1
DEB_DIMENTIO_V     ?= $(DIMENTIO_VERSION)

DIMENTIO_COMMIT    := 7ffffffd95119e439669aba5b3d0af36fff5ba17
DIMENTIO_SOVERSION := 0
DIMENTIO_LIBS      := -framework CoreFoundation -framework IOKit -lcompression

dimentio-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/dimentio-v$(DIMENTIO_VERSION).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/dimentio-v$(DIMENTIO_VERSION).tar.gz \
			https://github.com/0x7ff/dimentio/archive/$(DIMENTIO_COMMIT).tar.gz
	$(call EXTRACT_TAR,dimentio-v$(DIMENTIO_VERSION).tar.gz,dimentio-$(DIMENTIO_COMMIT),dimentio)
	mkdir -p $(BUILD_STAGE)/dimentio/usr/{bin,lib,include}

ifneq ($(wildcard $(BUILD_WORK)/dimentio/.build_complete),)
dimentio:
	@echo "Using previously built dimentio."
else
dimentio: dimentio-setup
	# libdimentio.o
	$(CC) $(CFLAGS) \
		-c -o $(BUILD_WORK)/dimentio/libdimentio.o -x c \
		$(BUILD_WORK)/dimentio/libdimentio.c

	# libdimentio.dylib
	$(CC) $(CFLAGS) -dynamiclib \
		-install_name "/usr/lib/libdimentio.$(DIMENTIO_SOVERSION).dylib" \
		-o $(BUILD_WORK)/dimentio/libdimentio.$(DIMENTIO_SOVERSION).dylib \
		$(BUILD_WORK)/dimentio/libdimentio.o \
		$(LDFLAGS) $(DIMENTIO_LIBS)

	# libdimentio.a
	$(LIBTOOL) -static \
		-o $(BUILD_WORK)/dimentio/libdimentio.a \
		$(BUILD_WORK)/dimentio/libdimentio.o

	# dimentio.o
	$(CC) $(CFLAGS) \
		-c -o $(BUILD_WORK)/dimentio/dimentio.o -x c \
		$(BUILD_WORK)/dimentio/dimentio.c

	# dimentio
	$(CC) $(CFLAGS) \
		-o $(BUILD_WORK)/dimentio/dimentio \
		$(BUILD_WORK)/dimentio/dimentio.o \
		$(BUILD_WORK)/dimentio/libdimentio.$(DIMENTIO_SOVERSION).dylib
	chmod u+s $(BUILD_WORK)/dimentio/dimentio

	cp -a $(BUILD_WORK)/dimentio/dimentio $(BUILD_STAGE)/dimentio/usr/bin
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_STAGE)/dimentio/usr/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_BASE)/usr/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_STAGE)/dimentio/usr/include
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_BASE)/usr/include
	touch $(BUILD_WORK)/dimentio/.build_complete
endif

dimentio-package: dimentio-stage
	# dimentio.mk Package Structure
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{$(DIMENTIO_SOVERSION),-dev}
	mkdir -p $(BUILD_DIST)/dimentio/usr/bin \
		$(BUILD_DIST)/libdimentio$(DIMENTIO_SOVERSION)/usr/lib \
		$(BUILD_DIST)/libdimentio-dev/usr/{lib,include}

	# dimentio.mk Prep libdimentio$(DIMENTIO_SOVERSION)
	cp -a $(BUILD_STAGE)/dimentio/usr/lib/libdimentio.$(DIMENTIO_SOVERSION).dylib $(BUILD_DIST)/libdimentio$(DIMENTIO_SOVERSION)/usr/lib

	# dimentio.mk Prep libdimentio-dev
	cp -a $(BUILD_STAGE)/dimentio/usr/lib/libdimentio.a $(BUILD_DIST)/libdimentio-dev/usr/lib
	cp -a $(BUILD_STAGE)/dimentio/usr/include/libdimentio.h $(BUILD_DIST)/libdimentio-dev/usr/include
	ln -s libdimentio.$(DIMENTIO_SOVERSION).dylib $(BUILD_DIST)/libdimentio-dev/usr/lib/libdimentio.dylib

	# dimentio.mk Prep dimentio
	cp -a $(BUILD_STAGE)/dimentio/usr/bin/dimentio $(BUILD_DIST)/dimentio/usr/bin

	# dimentio.mk Sign
	$(call SIGN,dimentio,dimentio.xml)
	$(call SIGN,libdimentio$(DIMENTIO_SOVERSION),dimentio.xml)

	# dimentio.mk Make .debs
	$(call PACK,dimentio,DEB_DIMENTIO_V)
	$(call PACK,libdimentio$(DIMENTIO_SOVERSION),DEB_DIMENTIO_V)
	$(call PACK,libdimentio-dev,DEB_DIMENTIO_V)

	# dimentio.mk Build cleanup
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{$(DIMENTIO_SOVERSION),-dev}

.PHONY: dimentio dimentio-package
