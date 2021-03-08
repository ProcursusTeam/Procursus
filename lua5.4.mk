ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lua5.4
LUA5.4_VERSION := 5.4.2
DEB_LUA5.4_V   ?= $(LUA5.4_VERSION)

lua5.4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA5.4_VERSION).tar.gz 
	$(call EXTRACT_TAR,lua-$(LUA5.4_VERSION).tar.gz,lua-$(LUA5.4_VERSION),lua5.4)
	$(call DO_PATCH,lua5.4,lua5.4,-p1)

ifneq ($(wildcard $(BUILD_WORK)/lua5.4/.build_complete),)
lua5.4:
	@echo "Using previously built lua5.4."
else
lua5.4: lua5.4-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua5.4 macosx \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) -fPIC -DLUA_COMPAT_5_3" \
		CXXFLAGS="$(CXXFLAGS) -fPIC -DLUA_COMPAT_5_3" \
		LDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)" \
		LUA_T="lua5.4" \
		LUAC_T="luac5.4" \
		LUA_A="liblua5.4.a" \
		LUAVER="5.4" \
		SOVER="0"
	+$(MAKE) -C $(BUILD_WORK)/lua5.4 install \
		INSTALL_TOP="$(BUILD_STAGE)/lua5.4/usr" \
		INSTALL_INC="$(BUILD_STAGE)/lua5.4/usr/include/lua5.4" \
		INSTALL_MAN="$(BUILD_STAGE)/lua5.4/usr/share/man/man1" \
		TO_BIN="lua5.4 luac5.4" \
		TO_LIB="liblua5.4.a liblua5.4.0.dylib"
	+$(MAKE) -C $(BUILD_WORK)/lua5.4 install \
		INSTALL_TOP="$(BUILD_BASE)/usr" \
		INSTALL_INC="$(BUILD_BASE)/usr/include/lua5.4" \
		INSTALL_MAN="$(BUILD_BASE)/usr/share/man/man1" \
		TO_BIN="lua5.4 luac5.4" \
		TO_LIB="liblua5.4.a liblua5.4.0.dylib"
	ln -sf liblua5.4.0.dylib $(BUILD_BASE)/usr/lib/liblua5.4.dylib
	touch $(BUILD_WORK)/lua5.4/.build_complete
endif

lua5.4-package: lua5.4-stage
	# lua5.4.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua5.4,liblua5.4-{0,dev}}
	mkdir -p $(BUILD_DIST)/lua5.4/usr/share \
		$(BUILD_DIST)/liblua5.4-{0,dev}/usr/lib
	
	# lua5.4.mk Prep lua5.4
	cp -a $(BUILD_STAGE)/lua5.4/usr/bin $(BUILD_DIST)/lua5.4/usr
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.4/usr/share/man/man1/lua.1 $(BUILD_DIST)/lua5.4/usr/share/man/man1/lua5.4.1
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.4/usr/share/man/man1/luac.1 $(BUILD_DIST)/lua5.4/usr/share/man/man1/luac5.4.1
	
	# lua5.4.mk Prep liblua5.4-0
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua5.4/usr/lib/liblua5.4.0.dylib $(BUILD_DIST)/liblua5.4-0/usr/lib/liblua5.4.0.dylib
	ln -sf liblua5.4.0.dylib $(BUILD_DIST)/liblua5.4-0/usr/lib/liblua5.4.0.0.0.dylib
	
	# lua5.4.mk Prep liblua5.4-dev
	cp -a $(BUILD_STAGE)/lua5.4/usr/include $(BUILD_DIST)/liblua5.4-dev/usr
	ln -sf liblua5.4.0.dylib $(BUILD_DIST)/liblua5.4-dev/usr/lib/liblua5.4.dylib
	
	# lua5.4.mk Sign
	$(call SIGN,lua5.4,general.xml)
	$(call SIGN,liblua5.4-0,general.xml)
	
	# lua5.4.mk Make .debs
	$(call PACK,lua5.4,DEB_LUA5.4_V)
	$(call PACK,liblua5.4-0,DEB_LUA5.4_V)
	$(call PACK,liblua5.4-dev,DEB_LUA5.4_V)
	
	# lua5.4.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lua5.4,liblua5.4-{0,dev}}

.PHONY: lua5.4 lua5.4-package
