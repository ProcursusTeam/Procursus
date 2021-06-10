ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += lua-luv
LUA-LUV_VERSION := 1.36.0
DEB_LUA-LUV_V   ?= $(LUA-LUV_VERSION)-1

lua-luv-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/lua-luv-$(LUA-LUV_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/lua-luv-$(LUA-LUV_VERSION).tar.gz \
			https://github.com/luvit/luv/releases/download/$(LUA-LUV_VERSION)-0/luv-$(LUA-LUV_VERSION)-0.tar.gz
	$(call EXTRACT_TAR,lua-luv-$(LUA-LUV_VERSION).tar.gz,luv-$(LUA-LUV_VERSION)-0,lua-luv/bundle)
	$(call DO_PATCH,lua-luv,lua-luv,-p1)
	mkdir -p $(BUILD_WORK)/lua-luv/{,bundle/}build5{1..3}
	mkdir -p $(BUILD_WORK)/lua-luv/buildjit

ifneq ($(wildcard $(BUILD_WORK)/lua-luv/.build_complete),)
lua-luv:
	@echo "Using previously built lua-luv."
else
lua-luv: lua-luv-setup libuv1 lua5.1 lua5.2 lua5.3 luajit
	for ver in {1..3}; do \
		cd $(BUILD_WORK)/lua-luv/build5$$ver && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
			-DLUA_BUILD_TYPE=System \
			-DWITH_SHARED_LIBUV=ON \
			-DBUILD_MODULE=OFF \
			-DBUILD_SHARED_LIBS=ON \
			-DWITH_LUA_ENGINE=Lua \
			-DLUA_INCLUDE_DIR="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			-DLUA_LIBRARY="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver.dylib" \
			-DSHAREDLIBS_INSTALL_INC_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver/luv" \
			..; \
		$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver; \
		$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver install \
			DESTDIR="$(BUILD_STAGE)/lua-luv"; \
		$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver install \
			DESTDIR="$(BUILD_BASE)"; \
		mv $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
		rm -f $(BUILD_BASE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.{1.,}dylib; \
		$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.1.dylib; \
		$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.dylib; \
		mv $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
		rm -f $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.{1.,}dylib; \
		$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.1.dylib; \
		$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.dylib; \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.1.dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.1.dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
		mv $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libluv.pc $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/lua5.$$ver-luv.pc; \
		sed -i "s/-lluv/-llua5.$$ver-luv/" $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/lua5.$$ver-luv.pc; \
		mv $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libluv.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/lua5.$$ver-luv.pc; \
		sed -i "s/-lluv/-llua5.$$ver-luv/" $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/lua5.$$ver-luv.pc; \
		cd $(BUILD_WORK)/lua-luv/bundle/build5$$ver && LDFLAGS="$(LDFLAGS) -undefined dynamic_lookup" cmake \
			$(DEFAULT_CMAKE_FLAGS) \
			-DLUA_BUILD_TYPE=System \
			-DWITH_SHARED_LIBUV=ON \
			-DBUILD_MODULE=ON \
			-DBUILD_SHARED_LIBS=ON \
			-DWITH_LUA_ENGINE=Lua \
			-DLUA_INCLUDE_DIR="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			-DSHAREDLIBS_INSTALL_INC_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver/luv" \
			..; \
		$(MAKE) -C $(BUILD_WORK)/lua-luv/bundle/build5$$ver; \
		$(MAKE) -C $(BUILD_WORK)/lua-luv/bundle/build5$$ver install \
			DESTDIR="$(BUILD_STAGE)/lua-luv"; \
	done
	cd $(BUILD_WORK)/lua-luv/buildjit && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DLUA_BUILD_TYPE=System \
		-DWITH_SHARED_LIBUV=ON \
		-DBUILD_MODULE=OFF \
		-DBUILD_SHARED_LIBS=ON \
		-DWITH_LUA_ENGINE=LuaJIT \
		-DLUAJIT_INCLUDE_DIR="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1" \
		-DLUA_LIBRARIES="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1.dylib" \
		-DSHAREDLIBS_INSTALL_INC_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1/luv" \
		../bundle
	$(MAKE) -C $(BUILD_WORK)/lua-luv/buildjit
	$(MAKE) -C $(BUILD_WORK)/lua-luv/buildjit install \
		DESTDIR="$(BUILD_STAGE)/lua-luv"
	$(MAKE) -C $(BUILD_WORK)/lua-luv/buildjit install \
		DESTDIR="$(BUILD_BASE)"
	mv $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib
	rm -f $(BUILD_BASE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.{1.,}dylib
	$(LN) -sf libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.1.dylib
	$(LN) -sf libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.dylib
	mv $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib
	rm -f $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluv.{1.,}dylib
	$(LN) -sf libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.1.dylib
	$(LN) -sf libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.1.dylib $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.1.dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-luv.$(LUA-LUV_VERSION).dylib
	mv $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libluv.pc $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/luajit-5.1-luv.pc
	sed -i "s/-lluv/-lluajit-5.1-luv/" $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/luajit-5.1-luv.pc
	mv $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libluv.pc $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/luajit-5.1-luv.pc
	sed -i "s/-lluv/-lluajit-5.1-luv/" $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/luajit-5.1-luv.pc
	touch $(BUILD_WORK)/lua-luv/.build_complete
endif

lua-luv-package: lua-luv-stage
	# lua-luv.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}
	mkdir -p $(BUILD_DIST)/lua-luv{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-luv.mk Prep lua-luv
	cp -a $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblua*5.*-luv.*.dylib,lua} $(BUILD_DIST)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-luv.mk Prep lua-luv-dev
	cp -a $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/lua-luv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/lua-luv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblua*5.*-luv.dylib,pkgconfig} $(BUILD_DIST)/lua-luv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-luv.mk Sign
	$(call SIGN,lua-luv,general.xml)

	# lua-luv.mk Make .debs
	$(call PACK,lua-luv,DEB_LUA-LUV_V)
	$(call PACK,lua-luv-dev,DEB_LUA-LUV_V)

	# lua-luv.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}

.PHONY: lua-luv lua-luv-package
