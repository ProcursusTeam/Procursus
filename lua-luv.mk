ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += lua-luv
LUA-LUV_VERSION := 1.36.0
DEB_LUA-LUV_V   ?= $(LUA-LUV_VERSION)

lua-luv-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/lua-luv-$(LUA-LUV_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/lua-luv-$(LUA-LUV_VERSION).tar.gz \
			https://github.com/luvit/luv/releases/download/$(LUA-LUV_VERSION)-0/luv-$(LUA-LUV_VERSION)-0.tar.gz
	$(call EXTRACT_TAR,lua-luv-$(LUA-LUV_VERSION).tar.gz,luv-$(LUA-LUV_VERSION)-0,lua-luv)
	$(call DO_PATCH,lua-luv,lua-luv,-p1)
	mkdir -p $(BUILD_WORK)/lua-luv/build5{1..3}

ifneq ($(wildcard $(BUILD_WORK)/lua-luv/.build_complete),)
lua-luv:
	@echo "Using previously built lua-luv."
else
lua-luv: lua-luv-setup libuv1 lua5.1 lua5.2 lua5.3
	for ver in {1..3}; do \
	cd $(BUILD_WORK)/lua-luv/build5$$ver && cmake \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DLUA_BUILD_TYPE=System \
		-DWITH_SHARED_LIBUV=ON \
		-DBUILD_MODULE=OFF \
		-DBUILD_SHARED_LIBS=ON \
		-DWITH_LUA_ENGINE=Lua \
		-DLUA_INCLUDE_DIR="$(BUILD_BASE)/usr/include/lua5.$$ver" \
		-DLUA_LIBRARY="$(BUILD_BASE)/usr/lib/liblua5.$$ver.a" \
		-DSHAREDLIBS_INSTALL_INC_DIR="/usr/include/lua5.$$ver/luv" \
		..; \
	$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver; \
	$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver install \
		DESTDIR="$(BUILD_STAGE)/lua-luv"; \
	$(MAKE) -C $(BUILD_WORK)/lua-luv/build5$$ver install \
		DESTDIR="$(BUILD_BASE)"; \
	mv $(BUILD_BASE)/usr/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/usr/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
	rm -f $(BUILD_BASE)/lua-luv/usr/lib/libluv.{1.,}dylib; \
	$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/usr/lib/liblua5.$$ver-luv.1.dylib; \
	$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/usr/lib/liblua5.$$ver-luv.dylib; \
	mkdir -p $(BUILD_BASE)/usr/lib/lua/5.$$ver/; \
	$(LN) -sf ../../liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_BASE)/usr/lib/lua/5.$$ver/luv.so; \
	mv $(BUILD_STAGE)/lua-luv/usr/lib/libluv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/usr/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
	rm -f $(BUILD_STAGE)/lua-luv/usr/lib/libluv.{1.,}dylib; \
	$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/usr/lib/liblua5.$$ver-luv.1.dylib; \
	$(LN) -sf liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/usr/lib/liblua5.$$ver-luv.dylib; \
	mkdir -p $(BUILD_STAGE)/lua-luv/usr/lib/lua/5.$$ver/; \
	$(LN) -sf ../../liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib $(BUILD_STAGE)/lua-luv/usr/lib/lua/5.$$ver/luv.so; \
	$(I_N_T) -id /usr/lib/liblua5.$$ver-luv.1.dylib $(BUILD_STAGE)/lua-luv/usr/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
	$(I_N_T) -id /usr/lib/liblua5.$$ver-luv.1.dylib $(BUILD_BASE)/usr/lib/liblua5.$$ver-luv.$(LUA-LUV_VERSION).dylib; \
	mv $(BUILD_STAGE)/lua-luv/usr/lib/pkgconfig/libluv.pc $(BUILD_STAGE)/lua-luv/usr/lib/pkgconfig/lua5.$$ver-luv.pc; \
	sed -i "s/-lluv/-llua5.$$ver-luv/" $(BUILD_STAGE)/lua-luv/usr/lib/pkgconfig/lua5.$$ver-luv.pc; \
	mv $(BUILD_BASE)/usr/lib/pkgconfig/libluv.pc $(BUILD_BASE)/usr/lib/pkgconfig/lua5.$$ver-luv.pc; \
	sed -i "s/-lluv/-llua5.$$ver-luv/" $(BUILD_BASE)/usr/lib/pkgconfig/lua5.$$ver-luv.pc; \
	done
	touch $(BUILD_WORK)/lua-luv/.build_complete
endif

lua-luv-package: lua-luv-stage
	# lua-luv.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}
	mkdir -p $(BUILD_DIST)/lua-luv{,-dev}/usr/lib
	
	# lua-luv.mk Prep lua-luv
	cp -a $(BUILD_STAGE)/lua-luv/usr/lib/{liblua5.*-luv.*.dylib,lua} $(BUILD_DIST)/lua-luv/usr/lib
	
	# lua-luv.mk Prep lua-luv-dev
	cp -a $(BUILD_STAGE)/lua-luv/usr/include $(BUILD_DIST)/lua-luv-dev/usr
	cp -a $(BUILD_STAGE)/lua-luv/usr/lib/{liblua5.*-luv.dylib,pkgconfig} $(BUILD_DIST)/lua-luv-dev/usr/lib
	
	# lua-luv.mk Sign
	$(call SIGN,lua-luv,general.xml)
	
	# lua-luv.mk Make .debs
	$(call PACK,lua-luv,DEB_LUA-LUV_V)
	$(call PACK,lua-luv-dev,DEB_LUA-LUV_V)
	
	# lua-luv.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}

.PHONY: lua-luv lua-luv-package
