ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += sqlite3
SQLITE3_VERSION  := 3.34.1
DEB_SQLITE3_V    ?= $(SQLITE3_VERSION)

sqlite3-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/s/sqlite3/sqlite3_$(SQLITE3_VERSION).orig.tar.xz
	$(call EXTRACT_TAR,sqlite3_$(SQLITE3_VERSION).orig.tar.xz,sqlite3-$(SQLITE3_VERSION),sqlite3)

	# I change the soversion here to allow installation to /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib on iOS where libsqlite3 is already in the shared cache.
	$(call DO_PATCH,sqlite3,sqlite3,-p1)

ifneq ($(wildcard $(BUILD_WORK)/sqlite3/.build_complete),)
sqlite3:
	@echo "Using previously built sqlite3."
else
sqlite3: sqlite3-setup ncurses readline
	cd $(BUILD_WORK)/sqlite3 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-readline \
		--disable-editline \
		--enable-session \
		--enable-json1 \
		--enable-fts4 \
		--enable-fts5 \
		--with-readline-inc="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/readline" \
		ac_cv_search_tgetent=-lncursesw \
		CPPFLAGS="$(CPPFLAGS) -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_MAX_VARIABLE_NUMBER=250000 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1 -DSQLITE_ENABLE_JSON1=1"
	+$(MAKE) -C $(BUILD_WORK)/sqlite3 all sqldiff
	+$(MAKE) -C $(BUILD_WORK)/sqlite3 install \
		DESTDIR="$(BUILD_STAGE)/sqlite3"
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lemon $(BUILD_WORK)/sqlite3/tool/lemon.c $(LDFLAGS)
	cp -a $(BUILD_WORK)/sqlite3/.libs/sqldiff $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lemon
	cp -a $(BUILD_WORK)/sqlite3/lempar.c $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lemon
	touch $(BUILD_WORK)/sqlite3/.build_complete
endif
sqlite3-package: sqlite3-stage
	# sqlite3.mk Package Structure
	rm -rf $(BUILD_DIST)/{sqlite3,lemon} $(BUILD_DIST)/libsqlite3-{1,dev}
	mkdir -p $(BUILD_DIST)/{sqlite3,lemon}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libsqlite3-{1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# sqlite3.mk Prep sqlite3
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{sqlite3,sqldiff} $(BUILD_DIST)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# sqlite3.mk Prep lemon
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/lemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lemon $(BUILD_DIST)/lemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# sqlite3.mk Prep libsqlite3-1
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsqlite3.1.dylib $(BUILD_DIST)/libsqlite3-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# sqlite3.mk Prep libsqlite3-dev
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsqlite3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/sqlite3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libsqlite3.{a,dylib}} $(BUILD_DIST)/libsqlite3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# sqlite3.mk Sign
	$(call SIGN,sqlite3,general.xml)
	$(call SIGN,lemon,general.xml)
	$(call SIGN,libsqlite3-1,general.xml)

	# sqlite3.mk Make .debs
	$(call PACK,sqlite3,DEB_SQLITE3_V)
	$(call PACK,lemon,DEB_SQLITE3_V)
	$(call PACK,libsqlite3-1,DEB_SQLITE3_V)
	$(call PACK,libsqlite3-dev,DEB_SQLITE3_V)

	# sqlite3.mk Build cleanup
	rm -rf $(BUILD_DIST)/{sqlite3,lemon} $(BUILD_DIST)/libsqlite3-{1,dev}

.PHONY: sqlite3 sqlite3-package
