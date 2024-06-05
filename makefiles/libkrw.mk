ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1800 ] && echo 1),1)

STRAPPROJECTS  += libkrw
LIBKRW_VERSION := 1.1.1
DEB_LIBKRW_V   ?= $(LIBKRW_VERSION)-1

LIBKRW_SOVERSION := 0

libkrw-setup: setup
	$(call GITHUB_ARCHIVE,Siguza,libkrw,$(LIBKRW_VERSION),$(LIBKRW_VERSION))
	$(call EXTRACT_TAR,libkrw-$(LIBKRW_VERSION).tar.gz,libkrw-$(LIBKRW_VERSION),libkrw)
	$(call DO_PATCH,libkrw,libkrw,-p1)
	mkdir -p $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/libkrw}
	sed -i 's|/usr/lib|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib|g' $(BUILD_WORK)/libkrw/src/libkrw.c

ifneq ($(wildcard $(BUILD_WORK)/libkrw/.build_complete),)
libkrw:
	@echo "Using previously built libkrw."
else
libkrw: libkrw-setup
	mkdir -p $(BUILD_WORK)/libkrw/src/.lib/

	# libkrw.o
	$(CC) $(CFLAGS) \
		-I$(BUILD_WORK)/libkrw/include \
		-c -o $(BUILD_WORK)/libkrw/src/.lib/libkrw.o \
		$(BUILD_WORK)/libkrw/src/libkrw.c

	# libkrw_tfp0.o
	$(CC) $(CFLAGS) \
		-I$(BUILD_WORK)/libkrw/include \
		-c -o $(BUILD_WORK)/libkrw/src/.lib/libkrw_tfp0.o \
		$(BUILD_WORK)/libkrw/src/libkrw_tfp0.c

	# libkrw.$(LIBKRW_SOVERSION).dylib
	$(CC) $(CFLAGS) -dynamiclib \
		-I$(BUILD_WORK)/libkrw/include \
		-install_name "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw.$(LIBKRW_SOVERSION).dylib" \
		-o $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw.$(LIBKRW_SOVERSION).dylib \
		$(BUILD_WORK)/libkrw/src/.lib/libkrw.o \
		$(LDFLAGS)

	# libkrw-tfp0.dylib
	$(CC) $(CFLAGS) -dynamiclib \
		-I$(BUILD_WORK)/libkrw/include \
		-install_name "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-tfp0.dylib" \
		-o $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-tfp0.dylib \
		$(BUILD_WORK)/libkrw/src/.lib/libkrw_tfp0.o \
		$(LDFLAGS)

	cp -a $(BUILD_WORK)/libkrw/include/libkrw{,_plugin}.h $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(LN_S) libkrw.$(LIBKRW_SOVERSION).dylib $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw.dylib
	$(call AFTER_BUILD,copy)
endif

libkrw-package: libkrw-stage
	# libkrw.mk Package Structure
	rm -rf $(BUILD_DIST)/libkrw{$(LIBKRW_SOVERSION){,-tfp0},-dev,}
	mkdir -p $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw \
		$(BUILD_DIST)/libkrw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-tfp0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw
	
	# libkrw.mk Prep libkrw$(LIBKRW_SOVERSION)
	cp -a $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw.$(LIBKRW_SOVERSION).dylib $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libkrw.mk Prep libkrw$(LIBKRW_SOVERSION)-tfp0
	cp -a $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-tfp0.dylib $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-tfp0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

	# libkrw.mk Prep libkrw-dev
	cp -a $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw.dylib $(BUILD_DIST)/libkrw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libkrw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libkrw{,_plugin}.h $(BUILD_DIST)/libkrw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libkrw.mk Sign
	$(call SIGN,libkrw$(LIBKRW_SOVERSION),general.xml)
	$(call SIGN,libkrw$(LIBKRW_SOVERSION)-tfp0,general.xml)

	# libkrw.mk Make .debs
	$(call PACK,libkrw$(LIBKRW_SOVERSION),DEB_LIBKRW_V)
	$(call PACK,libkrw$(LIBKRW_SOVERSION)-tfp0,DEB_LIBKRW_V)
	$(call PACK,libkrw-dev,DEB_LIBKRW_V)

	# libkrw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkrw{$(LIBKRW_SOVERSION){,-tfp0},-dev,}

.PHONY: libkrw libkrw-package

endif
endif
