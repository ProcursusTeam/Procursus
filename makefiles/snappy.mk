ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += snappy
SNAPPY_VERSION       := 1.3
SNAPPY_COMMIT        := 9c97ea03d941c0fcedc762222dacc4ea7b57c403
LIBSNAPPY_APFS_SOVER := 1
DEB_SNAPPY_V         ?= $(SNAPPY_VERSION)

snappy-setup: setup
	$(call GITHUB_ARCHIVE,sbingner,snappy,$(SNAPPY_COMMIT),$(SNAPPY_COMMIT))
	$(call EXTRACT_TAR,snappy-$(SNAPPY_COMMIT).tar.gz,snappy-$(SNAPPY_COMMIT),snappy)
	mkdir -p $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,include}

ifneq ($(wildcard $(BUILD_WORK)/snappy/.build_complete),)
snappy:
	@echo "Using previously built snappy."
else
# library name clash with libsnappy, so snappy => snappy-apfs
snappy: snappy-setup
	cd $(BUILD_WORK)/snappy && \
	$(CC) $(CFLAGS) -c libsnappy.m -o libsnappy.m.o; \
	$(CC) $(CFLAGS) -c libsnappy.c -o libsnappy.c.o; \
	$(CC) $(CFLAGS) -c snappy.c -o snappy.o; \
	$(AR) -crs -- $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.a libsnappy.{c,m}.o; \
	$(CC) $(CFLAGS) $(BUILD_MISC)/libiosexec/libiosexec.1.tbd -Wl,-compatibility_version,1.0.0 -Wl,-current_version,1.3.0 -shared -framework IOKit -framework CoreFoundation -framework Foundation libsnappy.{c,m}.o -o $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.$(LIBSNAPPY_APFS_SOVER).dylib; \
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.$(LIBSNAPPY_APFS_SOVER).dylib $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.dylib; \
	$(CC) $(CFLAGS) $(BUILD_MISC)/libiosexec/libiosexec.1.tbd snappy.o $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.$(LIBSNAPPY_APFS_SOVER).dylib  -framework IOKit -framework CoreFoundation -framework Foundation -o $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/snappy; \
	$(I_N_T) -change $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.$(LIBSNAPPY_APFS_SOVER).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.$(LIBSNAPPY_APFS_SOVER).dylib $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/snappy; \
	$(INSTALL) -m644 snappy.h $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/snappy-apfs.h
	$(call AFTER_BUILD,copy)
endif

snappy-package: snappy-stage
	# snappy.mk Package Structure
	rm -rf $(BUILD_DIST)/{snappy,libsnappy-apfs{1,-dev}}
	mkdir -p $(BUILD_DIST)/libsnappy-apfs{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# snappy.mk Prep snappy
	cp -af $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/snappy $(BUILD_DIST)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# snappy.mk Prep libsnappy-apfs1
	cp -af $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.1.dylib $(BUILD_DIST)/libsnappy-apfs1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# snappy.mk libsnappy-apfs-dev
	cp -a $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsnappy-apfs.dylib $(BUILD_DIST)/libsnappy-apfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -af $(BUILD_STAGE)/snappy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsnappy-apfs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# snappy.mk Sign
	$(call SIGN,snappy,snaputil.xml)
	
	# snappy.mk Make .debs
	$(call PACK,snappy,DEB_SNAPPY_V)
	$(call PACK,libsnappy-apfs1,DEB_SNAPPY_V)
	$(call PACK,libsnappy-apfs-dev,DEB_SNAPPY_V)
	
	# snappy.mk Build cleanup
	rm -rf $(BUILD_DIST)/{snappy,libsnappy-apfs{1,-dev}}

.PHONY: snappy snappy-package
