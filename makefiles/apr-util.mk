ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += apr-util
APR_UTIL_VERSION := 1.6.1
DEB_APR_UTIL_V   ?= $(APR_UTIL_VERSION)

apr-util-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://archive.apache.org/dist/apr/apr-util-$(APR_UTIL_VERSION).tar.bz2
	$(call EXTRACT_TAR,apr-util-$(APR_UTIL_VERSION).tar.bz2,apr-util-$(APR_UTIL_VERSION),apr-util)
	$(call DO_PATCH,apr-util,apr-util,-p1)

ifneq ($(wildcard $(BUILD_WORK)/apr-util/.build_complete),)
apr-util:
	@echo "Using previously built apr-util."
else
apr-util: apr-util-setup apr expat libgdbm openssl unixodbc
	cd $(BUILD_WORK)/apr-util && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--includedir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/apr-1.0 \
		--with-apr="$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--with-crypto \
		--with-gdbm="$(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--with-odbc="$(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--with-openssl="$(BUILD_STAGE)/openssl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--without-berkeley-db \
		--without-pgsql \
		APR_BUILD_DIR="$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/apr-1.0/build" \
		APR_INCLUDES="-I$(BUILD_BASE)/usr/include/apr-1.0" \
		APR_LIBS="-L$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -R$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lapr-1" \
		ac_cv_lib_crypto_EVP_CIPHER_CTX_new=yes \
		ac_cv_lib_ssl_SSL_accept=yes
	sed -i -e "s|^CC=.*$$|CC=$(CC)|" \
		-e "s|^CFLAGS=.*$$|CFLAGS=$(CFLAGS) -I$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/apr-1.0|" \
		-e "s|^CPPFLAGS=.*$$|CPPFLAGS=$(CPPFLAGS) -I$(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/apr-1.0|" \
		-e "s|^LDFLAGS=.*$$|LDFLAGS=$(LDFLAGS)|" $(BUILD_WORK)/apr-util/build/rules.mk
	for vars in apr_builddir apr_builders top_builddir; do sed -i "s|^$${vars}=.*$$|$${vars}=$(BUILD_STAGE)/apr/$(shell $(BUILD_STAGE)/apr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/apr-config --installbuilddir)|g" $(BUILD_WORK)/apr-util/build/rules.mk; done
	+$(MAKE) -C $(BUILD_WORK)/apr-util
	+$(MAKE) -C $(BUILD_WORK)/apr-util install \
		DESTDIR=$(BUILD_STAGE)/apr-util
	+$(MAKE) -C $(BUILD_WORK)/apr-util install \
		DESTDIR=$(BUILD_BASE)
	$(call AFTER_BUILD)
endif

apr-util-package: apr-util-stage
	# apr-util.mk Package Structure
	rm -rf $(BUILD_DIST)/libaprutil1{,-dbd-{sqlite3,odbc},-dev}
	mkdir -p $(BUILD_DIST)/libaprutil1{,-dbd-{sqlite3,odbc},-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1

	# apr-util.mk Prep libaprutil1
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaprutil-1{,.0}.dylib $(BUILD_DIST)/libaprutil1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1/apr_{crypto_openssl,dbm_gdbm}{,-1}.so $(BUILD_DIST)/libaprutil1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1

	# apr-util.mk Prep libaprutil1-dbd-odbc
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1/apr_dbd_odbc{,-1}.so $(BUILD_DIST)/libaprutil1-dbd-odbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1

	# apr-util.mk Prep libaprutil1-dbd-sqlite3
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1/apr_dbd_sqlite3{,-1}.so $(BUILD_DIST)/libaprutil1-dbd-sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/apr-util-1

	# apr-util.mk Prep libaprutil1-dev
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include} $(BUILD_DIST)/libaprutil1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libaprutil1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# apr-util.mk Sign
	$(call SIGN,libaprutil1,general.xml)
	$(call SIGN,libaprutil1-dbd-odbc,general.xml)
	$(call SIGN,libaprutil1-dbd-sqlite3,general.xml)

	# apr-util.mk Make .debs
	$(call PACK,libaprutil1,DEB_APR_UTIL_V)
	$(call PACK,libaprutil1-dbd-odbc,DEB_APR_UTIL_V)
	$(call PACK,libaprutil1-dbd-sqlite3,DEB_APR_UTIL_V)
	$(call PACK,libaprutil1-dev,DEB_APR_UTIL_V)

	# apr-util.mk Build cleanup
	rm -rf $(BUILD_DIST)/libaprutil1{,-dbd-{sqlite3,odbc},-dev}

.PHONY: apr-util apr-util-package
