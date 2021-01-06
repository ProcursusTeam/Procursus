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
	mkdir -p $(BUILD_WORK)/lua-luv/build

ifneq ($(wildcard $(BUILD_WORK)/lua-luv/.build_complete),)
lua-luv:
	@echo "Using previously built lua-luv."
else
lua-luv: lua-luv-setup libuv1 luajit
	cd $(BUILD_WORK)/lua-luv/build && cmake \
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
		..
	+$(MAKE) -C $(BUILD_WORK)/lua-luv/build
	+$(MAKE) -C $(BUILD_WORK)/lua-luv/build install \
		DESTDIR="$(BUILD_STAGE)/lua-luv"
	+$(MAKE) -C $(BUILD_WORK)/lua-luv/build install \
		DESTDIR="$(BUILD_BASE)"
	$(I_N_T) -id /usr/lib/libluv.1.dylib $(BUILD_STAGE)/lua-luv/usr/lib/libluv.1.36.0.dylib
	$(I_N_T) -id /usr/lib/libluv.1.dylib $(BUILD_BASE)/usr/lib/libluv.1.36.0.dylib
	touch $(BUILD_WORK)/lua-luv/.build_complete
endif

lua-luv-package: lua-luv-stage
	# lua-luv.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}
	mkdir -p $(BUILD_DIST)/lua-luv{,-dev}/usr/lib
	
	# lua-luv.mk Prep lua-luv
	cp -a $(BUILD_STAGE)/lua-luv/usr/lib/libluv.1{,.36.0}.dylib $(BUILD_DIST)/lua-luv/usr/lib
	
	# lua-luv.mk Prep lua-luv-dev
	cp -a $(BUILD_STAGE)/lua-luv/usr/include $(BUILD_DIST)/lua-luv-dev/usr
	cp -a $(BUILD_STAGE)/lua-luv/usr/lib/{libluv.dylib,pkgconfig} $(BUILD_DIST)/lua-luv-dev/usr/lib
	
	# lua-luv.mk Sign
	$(call SIGN,lua-luv,general.xml)
	
	# lua-luv.mk Make .debs
	$(call PACK,lua-luv,DEB_LUA-LUV_V)
	$(call PACK,lua-luv-dev,DEB_LUA-LUV_V)
	
	# lua-luv.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-luv{,-dev}

.PHONY: lua-luv lua-luv-package
