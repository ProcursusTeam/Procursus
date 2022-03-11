ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += unixodbc
UNIXODBC_VERSION := 2.3.9
DEB_UNIXODBC_V   ?= $(UNIXODBC_VERSION)-1

unixodbc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://fossies.org/linux/privat/unixODBC-$(UNIXODBC_VERSION).tar.gz
	$(call EXTRACT_TAR,unixODBC-$(UNIXODBC_VERSION).tar.gz,unixODBC-$(UNIXODBC_VERSION),unixodbc)
	$(call DO_PATCH,unixodbc,unixodbc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/unixodbc/.build_complete),)
unixodbc:
	@echo "Using previously built unixodbc."
else
unixodbc: unixodbc-setup libtool readline
	cd $(BUILD_WORK)/unixodbc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
		--enable-gui=no \
		--with-pth=no \
		--with-included-ltdl=no \
		libltdl_cv_need_uscore=no \
		lt_cv_dlopen_self=yes \
		lt_cv_dlopen_self_static=yes
	+$(MAKE) -C $(BUILD_WORK)/unixodbc \
		AM_LDFLAGS="-no-undefined -Wl,-dead_strip_dylibs"
	+$(MAKE) -C $(BUILD_WORK)/unixodbc install \
		DESTDIR=$(BUILD_STAGE)/unixodbc
	rm -f $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{autotest,unixodbc_conf}.h
	$(call AFTER_BUILD)
endif

unixodbc-package: unixodbc-stage
	# unixodbc.mk Package Structure
	rm -rf $(BUILD_DIST)/{unixodbc{,-common,-dev},libodbc{,cr,inst}2,odbcinst}
	mkdir -p $(BUILD_DIST)/{unixodbc{,-common},odbcinst}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man}
	mkdir -p $(BUILD_DIST)/{unixodbc-dev,libodbc{,cr,inst}2}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unixodbc.mk Prep libodbc2
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libodbc.2.dylib $(BUILD_DIST)/libodbc2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unixodbc.mk Prep libodbccr2
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libodbccr.2.dylib $(BUILD_DIST)/libodbccr2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unixodbc.mk Prep libodbcinst2
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libodbcinst.2.dylib $(BUILD_DIST)/libodbcinst2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unixodbc.mk Prep odbcinst
	mkdir -p $(BUILD_DIST)/odbcinst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/odbcinst $(BUILD_DIST)/odbcinst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/odbcinst.1 $(BUILD_DIST)/odbcinst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# unixodbc.mk Prep unixodbc
	# Some binaries was not installed but why? I wanna put them all but Debian don't
	mkdir -p $(BUILD_DIST)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{isql,iusql} $(BUILD_DIST)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{isql,iusql}.1 $(BUILD_DIST)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man7 $(BUILD_DIST)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# unixodbc.mk Prep unixodbc-common
	mkdir -p $(BUILD_DIST)/unixodbc-common/$(MEMO_PREFIX)/etc
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)/etc/odbc.ini $(BUILD_DIST)/unixodbc-common/$(MEMO_PREFIX)/etc
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5 $(BUILD_DIST)/unixodbc-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# unixodbc.mk Prep unixodbc-dev
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/unixodbc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/unixodbc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libodbc{,cr,inst}.{a,dylib},pkgconfig} $(BUILD_DIST)/unixodbc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unixodbc.mk Sign
	$(call SIGN,libodbc2,general.xml)
	$(call SIGN,libodbccr2,general.xml)
	$(call SIGN,libodbcinst2,general.xml)
	$(call SIGN,odbcinst,general.xml)
	$(call SIGN,unixodbc,general.xml)

	# unixodbc.mk Make .debs
	$(call PACK,libodbc2,DEB_UNIXODBC_V)
	$(call PACK,libodbccr2,DEB_UNIXODBC_V)
	$(call PACK,libodbcinst2,DEB_UNIXODBC_V)
	$(call PACK,odbcinst,DEB_UNIXODBC_V)
	$(call PACK,unixodbc,DEB_UNIXODBC_V)
	$(call PACK,unixodbc-common,DEB_UNIXODBC_V)
	$(call PACK,unixodbc-dev,DEB_UNIXODBC_V)

	# unixodbc.mk Build cleanup
	rm -rf $(BUILD_DIST)/{unixodbc{,-common,-dev},libodbc{,cr,inst}2,odbcinst}

.PHONY: unixodbc unixodbc-package
