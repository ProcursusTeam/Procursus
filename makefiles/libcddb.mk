ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libcddb
LIBCDDB_VERSION := 1.3.2
DEB_LIBCDDB_V   ?= $(LIBCDDB_VERSION)

libcddb-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/libc/libcddb/libcddb_$(LIBCDDB_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,libcddb_$(LIBCDDB_VERSION).orig.tar.gz,libcddb-$(LIBCDDB_VERSION),libcddb)
	echo "echo $(GNU_HOST_TRIPLE)" > $(BUILD_WORK)/libcddb/config.sub
	$(SED) -i -e 's|#define realloc rpl_realloc|/* IDK */|g' -e 's|#define malloc rpl_malloc|/* IDK */|g' $(BUILD_WORK)/libcddb/configure

ifneq ($(wildcard $(BUILD_WORK)/libcddb/.build_complete),)
libcddb:
	@echo "Using previously built libcddb."
else
libcddb: libcddb-setup
	cd $(BUILD_WORK)/libcddb && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libcddb
	+$(MAKE) -C $(BUILD_WORK)/libcddb install \
		DESTDIR=$(BUILD_STAGE)/libcddb
	+$(MAKE) -C $(BUILD_WORK)/libcddb install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libcddb/.build_complete
endif

libcddb-package: libcddb-stage
	# libcddb.mk Package Structure
	rm -rf $(BUILD_DIST)/libcddb{2,-dev}
	mkdir -p $(BUILD_DIST)/libcddb{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcddb.mk Prep libcddb2
	cp -a $(BUILD_STAGE)/libcddb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcddb.2.dylib $(BUILD_DIST)/libcddb2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcddb.mk Prep libcddb-dev
	cp -a $(BUILD_STAGE)/libcddb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcddb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcddb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libcddb.{dylib,a}} $(BUILD_DIST)/libcddb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libcddb.mk Sign
	$(call SIGN,libcddb2,general.xml)
	
	# libcddb.mk Make .debs
	$(call PACK,libcddb2,DEB_LIBCDDB_V)
	$(call PACK,libcddb-dev,DEB_LIBCDDB_V)
	
	# libcddb.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcddb{2,-dev}

.PHONY: libcddb libcddb-package
