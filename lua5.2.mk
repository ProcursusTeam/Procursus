ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lua5.2
LUA5.2_VERSION := 5.2.4
DEB_LUA5.2_V   ?= $(LUA5.2_VERSION)

lua5.2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA5.2_VERSION).tar.gz 
	$(call EXTRACT_TAR,lua-$(LUA5.2_VERSION).tar.gz,lua-$(LUA5.2_VERSION),lua5.2)
	$(call DO_PATCH,lua5.2,lua5.2,-p1)

ifneq ($(wildcard $(BUILD_WORK)/lua5.2/.build_complete),)
lua5.2:
	@echo "Using previously built lua5.2."
else
lua5.2: lua5.2-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 macosx \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) -fPIC" \
		CXXFLAGS="$(CXXFLAGS) -fPIC" \
		LDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)" \
		LUA_T="lua5.2" \
		LUAC_T="luac5.2" \
		LUA_A="liblua5.2.a" \
		LUAVER="5.2" \
		SOVER="0"
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 install \
		INSTALL_TOP="$(BUILD_STAGE)/lua5.2/usr" \
		INSTALL_INC="$(BUILD_STAGE)/lua5.2/usr/include/lua5.2" \
		INSTALL_MAN="$(BUILD_STAGE)/lua5.2/usr/share/man/man1" \
		TO_BIN="lua5.2 luac5.2" \
		TO_LIB="liblua5.2.a liblua5.2.0.dylib"
	+$(MAKE) -C $(BUILD_WORK)/lua5.2 install \
		INSTALL_TOP="$(BUILD_BASE)/usr" \
		INSTALL_INC="$(BUILD_BASE)/usr/include/lua5.2" \
		INSTALL_MAN="$(BUILD_BASE)/usr/share/man/man1" \
		TO_BIN="lua5.2 luac5.2" \
		TO_LIB="liblua5.2.a liblua5.2.0.dylib"
	ln -sf liblua5.2.0.dylib $(BUILD_BASE)/usr/lib/liblua5.2.dylib
	touch $(BUILD_WORK)/lua5.2/.build_complete
endif

lua5.2-package: lua5.2-stage
	# lua5.2.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua5.2,liblua5.2-{0,dev}}
	mkdir -p $(BUILD_DIST)/lua5.2/usr/share \
		$(BUILD_DIST)/liblua5.2-{0,dev}/usr/lib
	
	# lua5.2.mk Prep lua5.2
	cp -a $(BUILD_STAGE)/lua5.2/usr/bin $(BUILD_DIST)/lua5.2/usr
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.2/usr/share/man/man1/lua.1 $(BUILD_DIST)/lua5.2/usr/share/man/man2/lua5.2.1
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.2/usr/share/man/man1/luac.1 $(BUILD_DIST)/lua5.2/usr/share/man/man2/luac5.2.1
	
	# lua5.2.mk Prep liblua5.2-0
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua5.2/usr/lib/liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-0/usr/lib/liblua5.2.0.dylib
	ln -sf liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-0/usr/lib/liblua5.2.0.0.0.dylib
	
	# lua5.2.mk Prep liblua5.2-dev
	cp -a $(BUILD_STAGE)/lua5.2/usr/include $(BUILD_DIST)/liblua5.2-dev/usr
	ln -sf liblua5.2.0.dylib $(BUILD_DIST)/liblua5.2-dev/usr/lib/liblua5.2.dylib
	
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
