ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lua5.2
LUA5.2_VERSION := 5.2.4
DEB_LUA5.2_V   ?= $(LUA5.2_VERSION)-1

lua5.2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA5.2_VERSION).tar.gz
	$(call EXTRACT_TAR,lua-$(LUA5.2_VERSION).tar.gz,lua-$(LUA5.2_VERSION),lua5.2)
	$(call DO_PATCH,lua5.2,lua5.2,-p1)
	$(SED) -i -e ':a; s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g; ta' -e ':a; s|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g; ta' $(BUILD_WORK)/lua5.2/src/luaconf.h

ifneq ($(wildcard $(BUILD_WORK)/lua5.2/.build_complete),)
lua5.2:
	@echo "Using previously built lua5.2."
else
lua5.2: lua5.2-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 macosx \
		CC="$(CC)" \
		MYCFLAGS="$(CFLAGS) -fPIC" \
		MYLDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)" \
		LUA_T="lua5.2" \
		LUAC_T="luac5.2" \
		LUA_A="liblua5.2.a" \
		LUAVER="5.2" \
		SOVER="0"
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 install \
		INSTALL_TOP="$(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		INSTALL_INC="$(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.2" \
		INSTALL_MAN="$(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1" \
		TO_BIN="lua5.2 luac5.2" \
		TO_LIB="liblua5.2.a liblua5.2.0.dylib"
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 install \
		INSTALL_TOP="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		INSTALL_INC="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.2" \
		INSTALL_MAN="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1" \
		TO_BIN="lua5.2 luac5.2" \
		TO_LIB="liblua5.2.a liblua5.2.0.dylib"
	ln -sf liblua5.2.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.2.dylib
	touch $(BUILD_WORK)/lua5.2/.build_complete
endif

lua5.2-package: lua5.2-stage
	# lua5.2.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua5.2,liblua5.2-{0,dev}}
	mkdir -p $(BUILD_DIST)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/liblua5.2-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua5.2.mk Prep lua5.2
	cp -a $(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(INSTALL) -Dm644 $(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/lua.1 $(BUILD_DIST)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/lua5.2.1
	$(INSTALL) -Dm644 $(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/luac.1 $(BUILD_DIST)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/luac5.2.1

	# lua5.2.mk Prep liblua5.2-0
	$(INSTALL) -Dm755 $(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.2.0.dylib
	ln -sf liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.2.0.0.0.dylib

	# lua5.2.mk Prep liblua5.2-dev
	cp -a $(BUILD_STAGE)/lua5.2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liblua5.2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	ln -sf liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.2.dylib

	# lua5.2.mk Sign
	$(call SIGN,lua5.2,general.xml)
	$(call SIGN,liblua5.2-0,general.xml)

	# lua5.2.mk Make .debs
	$(call PACK,lua5.2,DEB_LUA5.2_V)
	$(call PACK,liblua5.2-0,DEB_LUA5.2_V)
	$(call PACK,liblua5.2-dev,DEB_LUA5.2_V)

	# lua5.2.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lua5.2,liblua5.2-{0,dev}}

.PHONY: lua5.2 lua5.2-package
