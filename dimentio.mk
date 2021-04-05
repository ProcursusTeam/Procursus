ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring arm64,$(MEMO_TARGET)))

SUBPROJECTS        += dimentio
DIMENTIO_COMMIT    := 7ffffff8367f5c8fccd4e76803c94a05e1c07fa1
DIMENTIO_VERSION   := 1.0.3+git20210403.$(shell echo $(DIMENTIO_COMMIT) | cut -c -7)
DEB_DIMENTIO_V     ?= $(DIMENTIO_VERSION)

DIMENTIO_SOVERSION := 0
DIMENTIO_LIBS      := -framework CoreFoundation -framework IOKit -lcompression

dimentio-setup: setup
	$(call GITHUB_ARCHIVE,0x7ff,dimentio,v$(DIMENTIO_COMMIT),$(DIMENTIO_COMMIT))
	$(call EXTRACT_TAR,dimentio-v$(DIMENTIO_COMMIT).tar.gz,dimentio-$(DIMENTIO_COMMIT),dimentio)
	mkdir -p $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,include}

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
		-install_name "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdimentio.$(DIMENTIO_SOVERSION).dylib" \
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

	cp -a $(BUILD_WORK)/dimentio/dimentio $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio*.{a,dylib} $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_WORK)/dimentio/libdimentio.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	touch $(BUILD_WORK)/dimentio/.build_complete
endif

dimentio-package: dimentio-stage
	# dimentio.mk Package Structure
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{$(DIMENTIO_SOVERSION),-dev}
	mkdir -p $(BUILD_DIST)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libdimentio$(DIMENTIO_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libdimentio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include}

	# dimentio.mk Prep libdimentio$(DIMENTIO_SOVERSION)
	cp -a $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdimentio.$(DIMENTIO_SOVERSION).dylib $(BUILD_DIST)/libdimentio$(DIMENTIO_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dimentio.mk Prep libdimentio-dev
	cp -a $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdimentio.a $(BUILD_DIST)/libdimentio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libdimentio.h $(BUILD_DIST)/libdimentio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	ln -s libdimentio.$(DIMENTIO_SOVERSION).dylib $(BUILD_DIST)/libdimentio-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdimentio.dylib

	# dimentio.mk Prep dimentio
	cp -a $(BUILD_STAGE)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dimentio $(BUILD_DIST)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# dimentio.mk Sign
	$(call SIGN,dimentio,dimentio.plist)
	$(call SIGN,libdimentio$(DIMENTIO_SOVERSION),dimentio.plist)

	# dimentio.mk Permissions
	chmod u+s $(BUILD_DIST)/dimentio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dimentio

	# dimentio.mk Make .debs
	$(call PACK,dimentio,DEB_DIMENTIO_V)
	$(call PACK,libdimentio$(DIMENTIO_SOVERSION),DEB_DIMENTIO_V)
	$(call PACK,libdimentio-dev,DEB_DIMENTIO_V)

	# dimentio.mk Build cleanup
	rm -rf $(BUILD_DIST)/dimentio $(BUILD_DIST)/libdimentio{$(DIMENTIO_SOVERSION),-dev}

.PHONY: dimentio dimentio-package

endif
