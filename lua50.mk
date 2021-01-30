ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lua50
LUA50_VERSION := 5.0.3
DEB_LUA50_V   ?= $(LUA50_VERSION)

lua50-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lua.org/ftp/lua-$(LUA50_VERSION).tar.gz 
	$(call EXTRACT_TAR,lua-$(LUA50_VERSION).tar.gz,lua-$(LUA50_VERSION),lua50)
	$(call DO_PATCH,lua50,lua50,-p1)

ifneq ($(wildcard $(BUILD_WORK)/lua50/.build_complete),)
lua50:
	@echo "Using previously built lua50."
else
lua50: lua50-setup readline
	+$(MAKE) -C $(BUILD_WORK)/lua50 all \
		CC="$(CC)" \
		MYCFLAGS="$(CFLAGS) -fPIC" \
		LDFLAGS="$(LDFLAGS)" \
		MYLDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)"
	+$(MAKE) -C $(BUILD_WORK)/lua50 so \
		CC="$(CC)" \
		MYCFLAGS="$(CFLAGS) -fPIC" \
		LDFLAGS="$(LDFLAGS)" \
		MYLDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)"
	+$(MAKE) -C $(BUILD_WORK)/lua50 sobin \
		CC="$(CC)" \
		MYCFLAGS="$(CFLAGS) -fPIC" \
		LDFLAGS="$(LDFLAGS)" \
		MYLDFLAGS="$(LDFLAGS)" \
		AR="$(AR) rcu" \
		RANLIB="$(RANLIB)"
	+$(MAKE) -C $(BUILD_WORK)/lua50 install \
		STRIP="$(STRIP)" \
		INSTALL_ROOT="$(BUILD_STAGE)/lua50/usr" \
		INSTALL_INC="$(BUILD_STAGE)/lua50/usr/include/lua50" \
		INSTALL_MAN="$(BUILD_STAGE)/lua50/usr/share/man/man1"
	+$(MAKE) -C $(BUILD_WORK)/lua50 soinstall \
		STRIP="$(STRIP)" \
		INSTALL_ROOT="$(BUILD_STAGE)/lua50/usr" \
		INSTALL_INC="$(BUILD_STAGE)/lua50/usr/include/lua50" \
		INSTALL_MAN="$(BUILD_STAGE)/lua50/usr/share/man/man1"
	+$(MAKE) -C $(BUILD_WORK)/lua50 install \
		STRIP="$(STRIP)" \
		INSTALL_ROOT="$(BUILD_BASE)/usr" \
		INSTALL_INC="$(BUILD_BASE)/usr/include/lua50" \
		INSTALL_MAN="$(BUILD_BASE)/usr/share/man/man1"
	+$(MAKE) -C $(BUILD_WORK)/lua50 soinstall \
		STRIP="$(STRIP)" \
		INSTALL_ROOT="$(BUILD_BASE)/usr" \
		INSTALL_INC="$(BUILD_BASE)/usr/include/lua50" \
		INSTALL_MAN="$(BUILD_BASE)/usr/share/man/man1"
	touch $(BUILD_WORK)/lua50/.build_complete
endif

lua50-package: lua50-stage
	# lua50.mk Package Structure
	rm -rf $(BUILD_DIST)/{lua50,liblua{,lib}50{,-dev}}
	mkdir -p $(BUILD_DIST)/lua50/usr/share \
		$(BUILD_DIST)/liblua{,lib}50{,-dev}/usr/lib
	
	# lua50.mk Prep lua50
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua50/usr/bin/lua $(BUILD_DIST)/lua50/usr/bin/lua50
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua50/usr/bin/luac $(BUILD_DIST)/lua50/usr/bin/luac50
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua50/usr/share/man/man1/lua.1 $(BUILD_DIST)/lua50/usr/share/man/man1/lua50.1
	$(GINSTALL) -Dm644 $(BUILD_STAGE)/lua50/usr/share/man/man1/luac.1 $(BUILD_DIST)/lua50/usr/share/man/man1/luac50.1
	
	# lua50.mk Prep liblua50
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua50/usr/lib/liblua50.5.0.dylib \
		$(BUILD_STAGE)/lua50/usr/lib/liblua50.5.dylib \
		$(BUILD_DIST)/liblua50/usr/lib/
	
	# lua50.mk Prep liblua50-dev
	cp -a $(BUILD_STAGE)/lua50/usr/include $(BUILD_DIST)/liblua50-dev/usr
	rm -f $(BUILD_DIST)/liblua50-dev/usr/include/lua50/lualib.h
	cp -a $(BUILD_STAGE)/lua50/usr/lib/liblua50.dylib $(BUILD_DIST)/liblua50-dev/usr/lib
	
	# lua50.mk Prep liblualib50
	$(GINSTALL) -Dm755 $(BUILD_STAGE)/lua50/usr/lib/liblualib50.5.0.dylib \
		$(BUILD_STAGE)/lua50/usr/lib/liblualib50.5.dylib \
		$(BUILD_DIST)/liblualib50/usr/lib/
	
	# lua50.mk Prep liblualib50-dev
	cp -a $(BUILD_STAGE)/lua50/usr/include $(BUILD_DIST)/liblualib50-dev/usr
	rm -f $(BUILD_DIST)/liblualib50-dev/usr/include/lua50/!(lualib.h)
	cp -a $(BUILD_STAGE)/lua50/usr/lib/liblualib50.dylib $(BUILD_DIST)/liblualib50-dev/usr/lib
	
	# lua50.mk Sign
	$(call SIGN,lua50,general.xml)
	$(call SIGN,liblua50,general.xml)
	$(call SIGN,liblualib50,general.xml)
	
	# lua50.mk Make .debs
	$(call PACK,lua50,DEB_LUA50_V)
	$(call PACK,liblua50,DEB_LUA50_V)
	$(call PACK,liblua50-dev,DEB_LUA50_V)
	$(call PACK,liblualib50,DEB_LUA50_V)
	$(call PACK,liblualib50-dev,DEB_LUA50_V)
	
	# lua50.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lua50,liblua{,lib}50{,-dev}}

.PHONY: lua50 lua50-package
