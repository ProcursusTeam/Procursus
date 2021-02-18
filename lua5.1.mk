ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lua5.1
LUA5.1_VERSION := 5.1.5
DEB_LUA5.1_V   ?= $(LUA5.1_VERSION)

lua5.1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA5.1_VERSION).tar.gz 
	$(call EXTRACT_TAR,lua-$(LUA5.1_VERSION).tar.gz,lua-$(LUA5.1_VERSION),lua5.1)
	$(call DO_PATCH,lua5.1,lua5.1,-p1)

ifneq ($(wildcard $(BUILD_WORK)/lua5.1/.build_complete),)
lua5.1:
	@echo "Using previously built lua5.1."
else
lua5.1: lua5.1-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua5.1 macosx \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) -fPIC" \
		CXXFLAGS="$(CXXFLAGS) -fPIC" \
		LDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)" \
		LUA_T="lua5.1" \
		LUAC_T="luac5.1" \
		LUA_A="liblua5.1.a" \
		LUAVER="5.1" \
		SOVER="0"
	+$(MAKE) -C $(BUILD_WORK)/lua5.1 install \
		INSTALL_TOP="$(BUILD_STAGE)/lua5.1/usr" \
		INSTALL_INC="$(BUILD_STAGE)/lua5.1/usr/include/lua5.1" \
		INSTALL_MAN="$(BUILD_STAGE)/lua5.1/usr/share/man/man1" \
		TO_BIN="lua5.1 luac5.1" \
		TO_LIB="liblua5.1.a liblua5.1.0.dylib"
	+$(MAKE) -C $(BUILD_WORK)/lua5.1 install \
		INSTALL_TOP="$(BUILD_BASE)/usr" \
		INSTALL_INC="$(BUILD_BASE)/usr/include/lua5.1" \
		INSTALL_MAN="$(BUILD_BASE)/usr/share/man/man1" \
		TO_BIN="lua5.1 luac5.1" \
		TO_LIB="liblua5.1.a liblua5.1.0.dylib"
	ln -sf liblua5.1.0.dylib $(BUILD_BASE)/usr/lib/liblua5.1.dylib
	touch $(BUILD_WORK)/lua5.1/.build_complete
endif

lua5.1-package: lua5.1-stage
	# lua5.1.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua5.1,liblua5.1-{0,dev}}
	mkdir -p $(BUILD_DIST)/lua5.1/usr/share \
		$(BUILD_DIST)/liblua5.1-{0,dev}/usr/lib
	
	# lua5.1.mk Prep lua5.1
	cp -a $(BUILD_STAGE)/lua5.1/usr/bin $(BUILD_DIST)/lua5.1/usr
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.1/usr/share/man/man1/lua.1 $(BUILD_DIST)/lua5.1/usr/share/man/man1/lua5.1.1
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua5.1/usr/share/man/man1/luac.1 $(BUILD_DIST)/lua5.1/usr/share/man/man1/luac5.1.1
	
	# lua5.1.mk Prep liblua5.1-0
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua5.1/usr/lib/liblua5.1.0.dylib $(BUILD_DIST)/liblua5.1-0/usr/lib/liblua5.1.0.dylib
	ln -sf liblua5.1.0.dylib $(BUILD_DIST)/liblua5.1-0/usr/lib/liblua5.1.0.0.0.dylib
	
	# lua5.1.mk Prep liblua5.1-dev
	cp -a $(BUILD_STAGE)/lua5.1/usr/include $(BUILD_DIST)/liblua5.1-dev/usr
	ln -sf liblua5.1.0.dylib $(BUILD_DIST)/liblua5.1-dev/usr/lib/liblua5.1.dylib
	
	# lua5.1.mk Sign
	$(call SIGN,lua5.1,general.xml)
	$(call SIGN,liblua5.1-0,general.xml)
	
	# lua5.1.mk Make .debs
	$(call PACK,lua5.1,DEB_LUA5.1_V)
	$(call PACK,liblua5.1-0,DEB_LUA5.1_V)
	$(call PACK,liblua5.1-dev,DEB_LUA5.1_V)
	
	# lua5.1.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lua5.1,liblua5.1-{0,dev}}

.PHONY: lua5.1 lua5.1-package
