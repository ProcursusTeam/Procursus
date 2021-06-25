ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lua5.3
LUA5.3_VERSION := 5.3.3
DEB_LUA5.3_V   ?= $(LUA5.3_VERSION)-1

lua5.3-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA5.3_VERSION).tar.gz
	$(call EXTRACT_TAR,lua-$(LUA5.3_VERSION).tar.gz,lua-$(LUA5.3_VERSION),lua5.3)
	$(call DO_PATCH,lua5.3,lua5.3,-p1)
	$(SED) -i -e ':a; s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g; ta' -e ':a; s|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g; ta' $(BUILD_WORK)/lua5.3/src/luaconf.h

ifneq ($(wildcard $(BUILD_WORK)/lua5.3/.build_complete),)
lua5.3:
	@echo "Using previously built lua5.3."
else
lua5.3: lua5.3-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua5.3 macosx \
		CC="$(CC)" \
		MYCFLAGS="$(CFLAGS) -fPIC -DLUA_COMPAT_5_3" \
		MYLDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)" \
		LUA_T="lua5.3" \
		LUAC_T="luac5.3" \
		LUA_A="liblua5.3.a" \
		LUAVER="5.3" \
		SOVER="0"
	+$(MAKE) -C $(BUILD_WORK)/lua5.3 install \
		INSTALL_TOP="$(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		INSTALL_INC="$(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.3" \
		INSTALL_MAN="$(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1" \
		TO_BIN="lua5.3 luac5.3" \
		TO_LIB="liblua5.3.a liblua5.3.0.dylib"
	+$(MAKE) -C $(BUILD_WORK)/lua5.3 install \
		INSTALL_TOP="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		INSTALL_INC="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.3" \
		INSTALL_MAN="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1" \
		TO_BIN="lua5.3 luac5.3" \
		TO_LIB="liblua5.3.a liblua5.3.0.dylib"
	ln -sf liblua5.3.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.3.dylib
	touch $(BUILD_WORK)/lua5.3/.build_complete
endif

lua5.3-package: lua5.3-stage
	# lua5.3.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua5.3,liblua5.3-{0,dev}}
	mkdir -p $(BUILD_DIST)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/liblua5.3-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua5.3.mk Prep lua5.3
	cp -a $(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(GINSTALL) -Dm633 $(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/lua.1 $(BUILD_DIST)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/lua5.3.1
	$(GINSTALL) -Dm633 $(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/luac.1 $(BUILD_DIST)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/luac5.3.1

	# lua5.3.mk Prep liblua5.3-0
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.3.0.dylib $(BUILD_DIST)/liblua5.3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.3.0.dylib
	ln -sf liblua5.3.0.dylib $(BUILD_DIST)/liblua5.3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.3.0.0.0.dylib

	# lua5.3.mk Prep liblua5.3-dev
	cp -a $(BUILD_STAGE)/lua5.3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liblua5.3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	ln -sf liblua5.3.0.dylib $(BUILD_DIST)/liblua5.3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.3.dylib

	# lua5.3.mk Sign
	$(call SIGN,lua5.3,general.xml)
	$(call SIGN,liblua5.3-0,general.xml)

	# lua5.3.mk Make .debs
	$(call PACK,lua5.3,DEB_LUA5.3_V)
	$(call PACK,liblua5.3-0,DEB_LUA5.3_V)
	$(call PACK,liblua5.3-dev,DEB_LUA5.3_V)

	# lua5.3.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lua5.3,liblua5.3-{0,dev}}

.PHONY: lua5.3 lua5.3-package
