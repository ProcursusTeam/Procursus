ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += aptitude
APTITUDE_VERSION := 0.8.13
DEB_APTITUDE_V   ?= $(APTITUDE_VERSION)

aptitude-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/a/aptitude/aptitude_$(APTITUDE_VERSION).orig.tar.xz
	$(call EXTRACT_TAR,aptitude_$(APTITUDE_VERSION).orig.tar.xz,aptitude-$(APTITUDE_VERSION),aptitude)
	$(call DO_PATCH,aptitude,aptitude,-p1)

ifneq ($(wildcard $(BUILD_WORK)/aptitude/.build_complete),)
aptitude:
	@echo "Using previously built aptitude."
else
aptitude: aptitude-setup ncurses libboost xapian cwidget apt googletest
	$(SED) -i 's|/usr/share/xml/docbook/stylesheet/nwalsh|$(DOCBOOK_XSL)|g' \
		$(BUILD_WORK)/aptitude/buildlib/docbook.mk \
		$(BUILD_WORK)/aptitude/doc/aptitude-{txt,man,html}.xsl \
		$(BUILD_WORK)/aptitude/doc/{de,nl,it,es,ja,en,ru,fr,pl,fi,cs}/Makefile.in
	cd $(BUILD_WORK)/aptitude && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-qt \
		--disable-gtk \
		--with-boost-libdir="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		--disable-boost-lib-checks \
		--disable-tests \
		--program-transform='s&aptitude$$&aptitude-curses&' \
		XAPIAN_CONFIG="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xapian-config" \
		SIGC_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sigc++-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sigc++-2.0/include" \
		CWIDGET_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/cwidget -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cwidget -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sigc++-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sigc++-2.0/include" \
		SQLITE3_CFLAGS="-I$(TARGET_SYSROOT)/usr/include" \
		SQLITE3_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lsqlite3" \
		CXXFLAGS="-std=gnu++17 $(CXXFLAGS) -D_XOPEN_SOURCE_EXTENDED" \
		CFLAGS="$(CFLAGS) -D_XOPEN_SOURCE_EXTENDED" \
		LIBS=" -lapt-pkg -lncursesw -lsigc-2.0 -lcwidget -lncursesw -lsigc-2.0 -lboost_iostreams.1.76.0 -lboost_system -lxapian -lpthread -lsqlite3" \
		pkgdata_DATA="" \
		DOCBOOK_TARGETS="docbook-man"
	+$(MAKE) -C $(BUILD_WORK)/aptitude \
		AR=$(AR) \
		FILESYSTEM_LDFLAGS="" \
		README="" \
		LIBS=" -lapt-pkg -lncursesw -lsigc-2.0 -lcwidget -lncursesw -lsigc-2.0 -lboost_iostreams.1.76.0 -lboost_system -lxapian -lpthread -lsqlite3" \
		DOCBOOK_TARGETS="docbook-man"
	+$(MAKE) -C $(BUILD_WORK)/aptitude install \
		DESTDIR=$(BUILD_STAGE)/aptitude \
		README="" \
		DOCBOOK_TARGETS="docbook-man"
	mv $(BUILD_STAGE)/aptitude/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/gl/man8/aptitude.8 $(BUILD_STAGE)/aptitude/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/gl/man8/aptitude-curses.8
	touch $(BUILD_WORK)/aptitude/.build_complete
endif

aptitude-package: aptitude-stage
	# aptitude.mk Package Structure
	rm -rf $(BUILD_DIST)/aptitude
	mkdir -p $(BUILD_DIST)/aptitude

	# aptitude.mk Prep aptitude
	cp -a $(BUILD_STAGE)/aptitude $(BUILD_DIST)

	# aptitude.mk Sign
	$(call SIGN,aptitude,general.xml)

	# aptitude.mk Make .debs
	$(call PACK,aptitude,DEB_APTITUDE_V)

	# aptitude.mk Build cleanup
	rm -rf $(BUILD_DIST)/aptitude

.PHONY: aptitude aptitude-package
