ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

BDB_VERSION := 18.1.32
DEB_BDB_V   ?= $(BDB_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/berkeleydb/.build_complete),)
berkeleydb:
	@echo "Using previously built berkeleydb."
else
berkeleydb: setup
	cd $(BUILD_WORK)/berkeleydb/dist && ./s_config
	cd $(BUILD_WORK)/berkeleydb/build_unix && ../dist/configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-static=no \
		--enable-shared=yes \
		--with-mutex=Darwin/_spin_lock_try
	$(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix install \
		DESTDIR=$(BUILD_STAGE)/berkeleydb
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/berkeleydb/build_unix install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/berkeleydb/.build_complete
endif

berkeleydb-stage: berkeleydb
	# berkeleydb.mk Package Structure
	rm -rf $(BUILD_DIST)/berkeleydb
	mkdir -p $(BUILD_DIST)/berkeleydb
	
	# berkeleydb.mk Prep berkeleydb
	cp -a $(BUILD_STAGE)/berkeleydb/usr $(BUILD_DIST)/berkeleydb
	rm -rf $(BUILD_DIST)/berkeleydb/usr/docs
	
	# berkeleydb.mk Sign
	$(call SIGN,berkeleydb,general.xml)
	
	# berkeleydb.mk Make .debs
	$(call PACK,berkeleydb,DEB_BDB_V)
	
	# berkeleydb.mk Build cleanup
	rm -rf $(BUILD_DIST)/berkeleydb

.PHONY: berkeleydb berkeleydb-stage
