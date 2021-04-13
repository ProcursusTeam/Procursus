ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  		+= mariadb
MARIADB_VERSION := 10.5.9
DEB_MARIADB_V   ?= $(MARIADB_VERSION)

mariadb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://downloads.mariadb.com/MariaDB/mariadb-$(MARIADB_VERSION)/source/mariadb-$(MARIADB_VERSION).tar.gz
	$(call EXTRACT_TAR,mariadb-$(MARIADB_VERSION).tar.gz,mariadb-$(MARIADB_VERSION),mariadb)
	$(call DO_PATCH,mariadb,mariadb,-p1)
	# wtf
	sed -i 's/END()/ENDIF()/' $(BUILD_WORK)/mariadb/libmariadb/cmake/ConnectorName.cmake

ifeq ($(UNAME),Linux)
	sed -i 's/COMMAND libtool/COMMAND $(GNU_HOST_TRIPLE)-libtool/' $(BUILD_WORK)/mariadb/cmake/libutils.cmake
endif

	mkdir -p $(BUILD_WORK)/mariadb/host

ifneq ($(wildcard $(BUILD_WORK)/mariadb/host/.build_complete),)
mariadb-import-executables:
	@echo "Using previously built mariadb-import-executables"
else
mariadb-import-executables: mariadb-setup
	# https://mariadb.com/kb/en/cross-compiling-mariadb/
	cd $(BUILD_WORK)/mariadb/host && \
		unset CC CXX CPP AR LD \
			RANLIB STRIP I_N_T NM LIPO OTOOL EXTRA LIBTOOL \
			CFLAGS CPPFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH PKG_CONFIG_LIBDIR ACLOCAL_PATH && \
		cmake .. \
			-DSTACK_DIRECTION=1 && \
		make import_executables
	touch $(BUILD_WORK)/mariadb/host/.build_complete
endif

ifneq ($(wildcard $(BUILD_WORK)/mariadb/.build_complete),)
mariadb:
	@echo "Using previously built mariadb."
else
mariadb: mariadb-import-executables openssl ncurses readline libevent curl lz4 libsnappy libunistring openpam libcrack
	# TODO: fix output structure to be consistent with debian
	cd $(BUILD_WORK)/mariadb && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCOMPILATION_COMMENT="Procursus" \
		-DDEB="Procursus" \
		-DSYSTEM_TYPE="debian-$(PLATFORM)" \
		-Wno-dev \
		-DINSTALL_SYSCONFDIR=$(MEMO_PREFIX)/etc \
		-DINSTALL_UNIX_ADDRDIR=$(MEMO_PREFIX)/var/run/mysqld/mysqld.sock \
		-DINSTALL_SCRIPTDIR=bin \
		-DINSTALL_INCLUDEDIR=include/mysql \
		-DINSTALL_PLUGINDIR=lib/mysql/plugin \
		-DINSTALL_SHAREDIR=share \
		-DINSTALL_SUPPORTFILESDIR=share/mysql \
		-DINSTALL_MYSQLSHAREDIR=share/mysql \
		-DINSTALL_DOCREADMEDIR=share/doc/mariadb \
		-DINSTALL_DOCDIR=share/doc/mariadb \
		-DINSTALL_MANDIR=share/man \
		-DMYSQL_DATADIR=$(MEMO_PREFIX)/var/lib/mysql \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DCONC_DEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_unicode_ci \
		-DENABLED_LOCAL_INFILE=ON \
		-DWITH_JEMALLOC=ON \
		-DWITH_PCRE=bundled \
		-DWITH_READLINE=ON \
		-DWITH_SSL=system \
		-DWITH_SYSTEMD=no \
		-DWITH_UNIT_TESTS=OFF \
		-DWITH_ZLIB=system \
		-DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DCMAKE_MODULE_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DCMAKE_SHARED_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DWITH_MYSQLCOMPAT=OFF \
		-DBUILD_CONFIG=mysql_release \
		-DPLUGIN_TOKUDB=NO \
		-DPLUGIN_CASSANDRA=NO \
		-DPLUGIN_AWS_KEY_MANAGEMENT=NO \
		-DPLUGIN_COLUMNSTORE=NO \
		-DWITH_INNODB_SNAPPY=ON \
		-DSTACK_DIRECTION=1 \
		-DHAVE_IB_GCC_ATOMIC_BUILTINS=1 \
		-DREADLINE_LIBRARY=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libreadline.dylib \
		-DLZ4_LIBS=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblz4.dylib \
		-DCURSES_LIBRARY=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib \
		-DCURL_LIBRARY=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcurl.dylib \
		-DLIBXML2_INCLUDE_DIR=$(TARGET_SYSROOT)/usr/include/libxml2 \
		-DICONV_LIBRARIES=$(TARGET_SYSROOT)/usr/lib/libiconv.tbd \
		-DIMPORT_EXECUTABLES=$(BUILD_WORK)/mariadb/host/import_executables.cmake \
		.

	+$(MAKE) -C $(BUILD_WORK)/mariadb
	+$(MAKE) -C $(BUILD_WORK)/mariadb install \
		DESTDIR="$(BUILD_STAGE)/mariadb"
	+$(MAKE) -C $(BUILD_WORK)/mariadb/{libmariadb,libmysqld,libservices,include} install \
		DESTDIR="$(BUILD_BASE)"

	# TODO: overwrite mariadb.pc with libmariadb.pc symlink

	# compatibility links
	ln -sf libmariadb.3.dylib $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadbclient.dylib
	ln -sf libmariadb.a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadbclient.a

	ln -sf libmariadb.3.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadbclient.dylib
	ln -sf libmariadb.a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadbclient.a

	# TODO: plugins compatibility links

	# lmao wtf
	mv $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqld.so $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqld.dylib
	#mv $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqld.so $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqld.dylib

	touch $(BUILD_WORK)/mariadb/.build_complete
endif

mariadb-package: mariadb-stage
	# mariadb.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libmariadb-dev{,-compat} \
		$(BUILD_DIST)/libmariadb{3,d{-dev,19}} \
		$(BUILD_DIST)/mariadb-{backup,client-10.5,client-core,common} \
		$(BUILD_DIST)/mariadb-plugin-{connect,cracklib-password-check,gssapi-client,gssapi-server,oqgraph,rocksdb,s3,spider} \
		$(BUILD_DIST)/mariadb-server-{10.5,core-10.5} \
		$(BUILD_DIST)/mariadb-test{,-data}

	# TODO: finish creating packages

	# mariadb.mk Prep libmariadb-dev-compat
	mkdir -p $(BUILD_DIST)/libmariadb-dev-compat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqlclient{,_r}.{a,dylib} \
		$(BUILD_DIST)/libmariadb-dev-compat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mariadb.mk Prep libmariadb-dev
	mkdir -p $(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,share/man/man1,includes/mariadb}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mariadb{-,_}config \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mariadb/{errmsg,ma_{list,pvio,tls},mariadb_{com,ctype,dyncol,rpl,stmt,version},my_{config,global,sys},mysql{,_{com,version}},mysqld_error}.h \
			$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/includes/mariadb
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mariadb/{mariadb,mysql} \
			$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/includes/mariadb
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadb{,client}.{a,dylib} \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmysqlservices.a \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{mariadb,mysql}_config.1 \
		$(BUILD_DIST)/libmariadb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep libmariadb3
	mkdir -p $(BUILD_DIST)/libmariadb3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadb.3.dylib $(BUILD_DIST)/libmariadb3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadb3 $(BUILD_DIST)/libmariadb3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mariadb.mk Prep libmariadbd-dev
	mkdir -p $(BUILD_DIST)/libmariadbd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/mariadb}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mariadb/server $(BUILD_DIST)/libmariadbd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mariadb
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib{mariadb,mysql}d.{a,dylib} $(BUILD_DIST)/libmariadbd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mariadb.mk Prep libmariadbd19
	mkdir -p $(BUILD_DIST)/libmariadbd19/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmariadbd.19.dylib $(BUILD_DIST)/libmariadbd19/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mariadb.mk Prep mariadb-backup
	mkdir -p $(BUILD_DIST)/mariadb-backup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{mariadb-backup,mbstream} $(BUILD_DIST)/mariadb-backup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{mariabackup,mariadb-backup,mbstream}.1 $(BUILD_DIST)/mariadb-backup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep mariadb-client-10.5
	## TODO: copy configs
	mkdir -p $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mariadb-{access,admin,conv,dump,dumpslow,find-rows,fix-extensions,import,show,slap,waitpid} $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mytop $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/mariadb-{access,admin,conv,dump,dumpslow,find-rows,fix-extensions,import,show,slap,waitpid}.1 $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/mysql{_{find_rows,fix_extensions,waitpid},access,admin,dump,dumpslow,import,show,slap}.1 $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/mytop.1 $(BUILD_DIST)/mariadb-client-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep mariadb-client-core-10.5
	## TODO: copy configs
	mkdir -p $(BUILD_DIST)/mariadb-client-core-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mariadb{,-check} $(BUILD_DIST)/mariadb-client-core-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/mariadb{,-check}.1 $(BUILD_DIST)/mariadb-client-core-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/mysql{,check}.1 $(BUILD_DIST)/mariadb-client-core-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep mariadb-common
	## TODO: copy configs

	# mariadb.mk Prep mariadb-plugin-connect
	mkdir -p $(BUILD_DIST)/mariadb-plugin-connect/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/lib/mysql/plugin}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/connect.cnf $(BUILD_DIST)/mariadb-plugin-connect/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_connect.so $(BUILD_DIST)/mariadb-plugin-connect/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# mariadb.mk Prep mariadb-plugin-cracklib-password-check
	mkdir -p $(BUILD_DIST)/mariadb-plugin-cracklib-password-check/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/lib/mysql/plugin}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/cracklib_password_check.cnf $(BUILD_DIST)/mariadb-plugin-cracklib-password-check/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/cracklib_password_check.so $(BUILD_DIST)/mariadb-plugin-cracklib-password-check/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# TODO: Need to port kerberos
	# # mariadb.mk Prep mariadb-plugin-auth-gssapi-client
	# mkdir -p $(BUILD_DIST)/mariadb-plugin-auth-gssapi-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin
	# cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/auth_gssapi_client.so $(BUILD_DIST)/mariadb-plugin-auth-gssapi-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# # mariadb.mk Prep mariadb-plugin-auth-gssapi-server
	# mkdir -p $(BUILD_DIST)/mariadb-plugin-auth-gssapi-server/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/lib/mysql/plugin}
	# cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/auth_gssapi.cnf $(BUILD_DIST)/mariadb-plugin-auth-gssapi-server/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	# cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/auth_gssapi.so $(BUILD_DIST)/mariadb-plugin-auth-gssapi-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# mariadb.mk Prep mariadb-plugin-mroonga
	mkdir -p $(BUILD_DIST)/mariadb-plugin-mroonga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/mysql/plugin,share/mysql}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_mroonga.so $(BUILD_DIST)/mariadb-plugin-mroonga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mysql/mroonga $(BUILD_DIST)/mariadb-plugin-mroonga/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mysql

	# TODO: fix libboost compiling
	# # mariadb.mk Prep mariadb-plugin-oqgraph
	# mkdir -p $(BUILD_DIST)/mariadb-plugin-oqgraph/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/lib/mysql/plugin}
	# cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/ha_oqgraph.cnf $(BUILD_DIST)/mariadb-plugin-oqgraph/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	# cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_oqgraph.so $(BUILD_DIST)/mariadb-plugin-oqgraph/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# mariadb.mk Prep mariadb-plugin-rocksdb
	mkdir -p $(BUILD_DIST)/mariadb-plugin-rocksdb/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/{bin,lib/mysql/plugin,share/man/man1}}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/rocksdb.cnf $(BUILD_DIST)/mariadb-plugin-rocksdb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_rocksdb.so $(BUILD_DIST)/mariadb-plugin-rocksdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{mariadb-ldb,myrocks_hotbackup} $(BUILD_DIST)/mariadb-plugin-rocksdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{mariadb-ldb,myrocks_hotbackup,mysql_ldb}.1 $(BUILD_DIST)/mariadb-plugin-rocksdb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep mariadb-plugin-s3
	mkdir -p $(BUILD_DIST)/mariadb-plugin-s3/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/{bin,lib/mysql/plugin,share/man/man1}}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/s3.cnf $(BUILD_DIST)/mariadb-plugin-s3/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_s3.so $(BUILD_DIST)/mariadb-plugin-s3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/aria_s3_copy $(BUILD_DIST)/mariadb-plugin-s3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/aria_s3_copy.1 $(BUILD_DIST)/mariadb-plugin-s3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# mariadb.mk Prep mariadb-plugin-spider
	mkdir -p $(BUILD_DIST)/mariadb-plugin-spider/$(MEMO_PREFIX)/{etc/mysql/mariadb.conf.d,$(MEMO_SUB_PREFIX)/lib/mysql/plugin}
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d/spider.cnf $(BUILD_DIST)/mariadb-plugin-spider/$(MEMO_PREFIX)/etc/mysql/mariadb.conf.d
	cp -a $(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/ha_spider.so $(BUILD_DIST)/mariadb-plugin-spider/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin

	# mariadb.mk Prep mariadb-server-10.5
	mkdir -p \
		$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)/{etc/mysql} \
		$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/mysql/plugin,share/{doc,mariadb-server-10.5,man/man1,mysql}}
	# TODO: add galera
	# galera_{new_cluster,recovery}
	# mariadb-{service-convert,multi,safe,safe-helper}
	cp -a \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{aria_{chk,dump_log,ftdump,pack,read_log},mariadb-{binlog,convert-table-format,hotcopy,plugin,secure-installation,setpermission,tzinfo-to-sql}} \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{msql2mysql,myisam{_ftdump,chk,log,pack},perror,replace,resolve_stack_dump,wsrep_sst_{common,mariabackup,mysqldump,rsync{,_wan}}} \
		$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	# TODO:
	# lib/mysql/plugin/disks.so
	cp -a \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/auth_pam_tool_dir \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/{auth_{ed25519,pam{,_v1}},file_key_management,ha_{archive,blackhole,federated{,x},sphinx},handlersocket,locales,metadata_lock_info}.so \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin/{query_{cache_info,response_time},server_audit,simple_password_check,sql_errlog,type_mysql_json,wsrep_info}.so \
		$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mysql/plugin
	# TODO: add galera
	# galera_{new_cluster,recovery}
	# mariadb-{service-convert,multi,safe,safe-helper}
	cp -a \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{aria_{chk,dump_log,ftdump,pack,read_log},mariadb-{binlog,convert-table-format,hotcopy,plugin,secure-installation,setpermission,tzinfo-to-sql}}.1 \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{mariadbd-{multi,safe{,-helper}},msql2mysql,myisam{_ftdump,chk,log,pack},mysql{_{convert_table_format,plugin,secure_installation,tzinfo_to_sql},binlog,d_{multi,safe{,_helper}},hotcopy}}.1 \
		$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{perror,replace,resolve_stack_dump,wsrep_sst_{common,mariabackup,mysqldump,rsync{,_wan}}}.1 \
		$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	# cp -a \
	# 	$(BUILD_STAGE)/mariadb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mysql/{errmsg-utf8.txt,wsrep{.conf,_notify}} \
	# 	$(BUILD_DIST)/mariadb-server-10.5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mysql


	# mariadb.mk Sign
	$(call SIGN,libmariadb-dev-compat,general.xml)

	# mariadb.mk Make .debs
	$(call PACK,libmariadb-dev-compat,DEB_MARIADB_V)

	# mariadb.mk Build cleanup
	rm -rf \
		$(BUILD_DIST)/libmariadb-dev{,-compat} \
		$(BUILD_DIST)/libmariadb{3,d{-dev,19}} \
		$(BUILD_DIST)/mariadb-{backup,client-10.5,client-core,common} \
		$(BUILD_DIST)/mariadb-plugin-{connect,cracklib-password-check,gssapi-client,gssapi-server,oqgraph,rocksdb,s3,spider} \
		$(BUILD_DIST)/mariadb-server-{10.5,core-10.5} \
		$(BUILD_DIST)/mariadb-test{,-data}

.PHONY: mariadb mariadb-package
