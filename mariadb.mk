ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mariadb
MARIADB_VERSION := 10.5.5
DEB_MARIADB_V   ?= $(MARIADB_VERSION)

mariadb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://downloads.mariadb.com/MariaDB/mariadb-$(MARIADB_VERSION)/source/mariadb-$(MARIADB_VERSION).tar.gz
	$(call EXTRACT_TAR,mariadb-$(MARIADB_VERSION).tar.gz,mariadb-$(MARIADB_VERSION),mariadb)
	$(call DO_PATCH,mariadb,mariadb,-p1)

ifeq ($(UNAME),Linux)
	sed -i 's/COMMAND libtool/COMMAND $(GNU_HOST_TRIPLE)-libtool/' $(BUILD_WORK)/mariadb/cmake/libutils.cmake
endif

	mkdir -p $(BUILD_WORK)/mariadb/host
ifneq ($(wildcard $(BUILD_WORK)/mariadb/host/.build_complete),)
mariadb-import-executables:
	@echo "Using previously built mariadb-import-executables"
else
mariadb-import-executables:
	# https://mariadb.com/kb/en/cross-compiling-mariadb/
	cd $(BUILD_WORK)/mariadb/host \
	&& unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && \
			CC=$(shell which cc) \
			CXX=$(shell which c++) \
			cmake .. \
				-DSTACK_DIRECTION=1 \
		&& make import_executables
	touch $(BUILD_WORK)/mariadb/host/.build_complete
endif

ifneq ($(wildcard $(BUILD_WORK)/mariadb/.build_complete),)
mariadb:
	@echo "Using previously built mariadb."
else
mariadb: mariadb-setup mariadb-import-executables openssl ncurses readline libevent curl lz4 libsnappy libunistring
	cd $(BUILD_WORK)/mariadb && LIBTOOL=$(GNU_HOST_TRIPLE)-libtool cmake . \
		-DCOMPILATION_COMMENT="iOS Procursus" \
		-Wno-dev \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DINSTALL_SYSCONFDIR=/etc \
		-DINSTALL_SYSCONF2DIR=/etc/my.cnf.d \
		-DINSTALL_UNIX_ADDRDIR=/var/run/mysqld/mysqld.sock \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DINSTALL_SCRIPTDIR=bin \
		-DINSTALL_INCLUDEDIR=include/mysql \
		-DINSTALL_PLUGINDIR=lib/mysql/plugin \
		-DINSTALL_SHAREDIR=share \
		-DINSTALL_SUPPORTFILESDIR=share/mysql \
		-DINSTALL_MYSQLSHAREDIR=share/mysql \
		-DINSTALL_DOCREADMEDIR=share/doc/mariadb \
		-DINSTALL_DOCDIR=share/doc/mariadb \
		-DINSTALL_MANDIR=share/man \
		-DMYSQL_DATADIR=/var/lib/mysql \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_unicode_ci \
		-DENABLED_LOCAL_INFILE=ON \
		-DPLUGIN_EXAMPLE=NO \
		-DPLUGIN_FEDERATED=NO \
		-DPLUGIN_FEEDBACK=NO \
		-DWITH_EMBEDDED_SERVER=ON \
		-DWITH_EXTRA_CHARSETS=complex \
		-DWITH_JEMALLOC=ON \
		-DWITH_LIBWRAP=OFF \
		-DWITH_PCRE=bundled \
		-DWITH_READLINE=ON \
		-DWITH_SSL=system \
		-DWITH_SYSTEMD=no \
		-DWITH_UNIT_TESTS=OFF \
		-DWITH_ZLIB=system \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DCMAKE_MODULE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DCMAKE_SHARED_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(TARGET_SYSROOT)/usr/lib -liconv -lsnappy -lxml2" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DSTACK_DIRECTION=1 \
		-DHAVE_IB_GCC_ATOMIC_BUILTINS=1 \
		-DREADLINE_LIBRARY=$(BUILD_BASE)/usr/lib/libreadline.dylib \
		-DLZ4_LIBS=$(BUILD_BASE)/usr/lib/liblz4.dylib \
		-DCURSES_LIBRARY=$(BUILD_BASE)/usr/lib/libncursesw.dylib \
		-DCURL_LIBRARY=$(BUILD_BASE)/usr/lib/libcurl.dylib \
		-DLIBXML2_INCLUDE_DIR=$(TARGET_SYSROOT)/usr/include \
		-DICONV_LIBRARIES=$(TARGET_SYSROOT)/usr/lib/libiconv.tbd \
		-DIMPORT_EXECUTABLES=$(BUILD_WORK)/mariadb/host/import_executables.cmake

	+$(MAKE) -C $(BUILD_WORK)/mariadb LIBTOOL=$(GNU_HOST_TRIPLE)-libtool
	+$(MAKE) -C $(BUILD_WORK)/mariadb install \
		DESTDIR="$(BUILD_STAGE)/mariadb"
	+$(MAKE) -C $(BUILD_WORK)/mariadb/{libmariadb,libmysqld,libservices,include} install \
		DESTDIR="$(BUILD_BASE)"
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
	mkdir -p \
		$(BUILD_DIST)/libmariadb-dev{,-compat}/usr/lib \

	# mariadb.mk Prep libmariadb-dev-compat
	cp -a $(BUILD_STAGE)/mariadb/usr/lib/libmysqlclient{,_r}.{a,dylib} $(BUILD_DIST)/libmariadb-dev-compat/usr/lib


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
