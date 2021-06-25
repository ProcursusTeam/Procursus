ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += berkeleydb
# Berkeleydb requires registration on Oracle's website, so this is a mirror.
BDB_VERSION := 18.1.40
DEB_BDB_V   ?= $(BDB_VERSION)

berkeleydb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://fossies.org/linux/misc/db-$(BDB_VERSION).tar.gz
	$(call EXTRACT_TAR,db-$(BDB_VERSION).tar.gz,db-$(BDB_VERSION),berkeleydb)
	$(call DO_PATCH,berkeleydb,berkeleydb,-p1)

ifneq ($(wildcard $(BUILD_WORK)/berkeleydb/.build_complete),)
berkeleydb:
	@echo "Using previously built berkeleydb."
else
berkeleydb: berkeleydb-setup gettext openssl
	cd $(BUILD_WORK)/berkeleydb/dist && ./s_config
	cd $(BUILD_WORK)/berkeleydb/build_unix && ../dist/configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--includedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181 \
		--enable-cxx \
		--enable-compat185 \
		--enable-sql \
		--enable-sql_codegen \
		--enable-dbm \
		--enable-stl \
		--with-mutex=Darwin/_spin_lock_try
	+$(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix
	+$(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix install \
		DESTDIR=$(BUILD_STAGE)/berkeleydb
	+$(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/berkeleydb/.build_complete
endif

berkeleydb-package: berkeleydb-stage
	# berkeleydb.mk Package Structure
	rm -rf $(BUILD_DIST)/db18.1-util \
		$(BUILD_DIST)/libdb18.1{,++,-stl}{,-dev}
	mkdir -p $(BUILD_DIST)/db18.1-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libdb18.1{,++,-stl}{/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/db181}}

	# berkeleydb.mk Prep db18.1-util
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/db18.1-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# berkeleydb.mk Prep libdb18.1
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb-18{,.1}.dylib $(BUILD_DIST)/libdb18.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# berkeleydb.mk Prep libdb18.1++
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb_cxx-18{,.1}.dylib $(BUILD_DIST)/libdb18.1++/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# berkeleydb.mk Prep libdb18.1-stl
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb_stl-18{,.1}.dylib $(BUILD_DIST)/libdb18.1-stl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# berkeleydb.mk Prep libdb18.1-dev
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb{-18.1.a,.dylib} $(BUILD_DIST)/libdb18.1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181/db{,_185}.h $(BUILD_DIST)/libdb18.1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181

	# berkeleydb.mk Prep libdb18.1++-dev
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb_cxx{-18.1.a,.dylib} $(BUILD_DIST)/libdb18.1++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181/db_cxx.h $(BUILD_DIST)/libdb18.1++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181

	# berkeleydb.mk Prep libdb18.1-stl-dev
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdb_stl{-18.1.a,.dylib} $(BUILD_DIST)/libdb18.1-stl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/berkeleydb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181/dbstl*.h $(BUILD_DIST)/libdb18.1-stl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/db181

	# berkeleydb.mk Sign
	$(call SIGN,db18.1-util,general.xml)
	$(call SIGN,libdb18.1,general.xml)
	$(call SIGN,libdb18.1++,general.xml)
	$(call SIGN,libdb18.1-stl,general.xml)

	# berkeleydb.mk Make .debs
	$(call PACK,db18.1-util,DEB_BDB_V)
	$(call PACK,libdb18.1,DEB_BDB_V)
	$(call PACK,libdb18.1++,DEB_BDB_V)
	$(call PACK,libdb18.1-stl,DEB_BDB_V)
	$(call PACK,libdb18.1-dev,DEB_BDB_V)
	$(call PACK,libdb18.1++-dev,DEB_BDB_V)
	$(call PACK,libdb18.1-stl-dev,DEB_BDB_V)

	# berkeleydb.mk Build cleanup
	rm -rf $(BUILD_DIST)/db18.1-util \
		$(BUILD_DIST)/libdb18.1{,++,-stl}{,-dev}

.PHONY: berkeleydb berkeleydb-package
