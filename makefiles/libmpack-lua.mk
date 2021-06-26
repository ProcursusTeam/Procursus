ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += libmpack-lua
LIBMPACK-LUA_VERSION := 1.0.8
DEB_LIBMPACK-LUA_V   ?= $(LIBMPACK-LUA_VERSION)

libmpack-lua-setup: setup
	$(call GITHUB_ARCHIVE,libmpack,libmpack-lua,$(LIBMPACK-LUA_VERSION),$(LIBMPACK-LUA_VERSION))
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build51)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build51/bundle)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build52)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build52/bundle)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build53)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/build53/bundle)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/buildjit)
	$(call EXTRACT_TAR,libmpack-lua-$(LIBMPACK-LUA_VERSION).tar.gz,libmpack-lua-$(LIBMPACK-LUA_VERSION),libmpack-lua/buildjit/bundle)
	for ver in {1..3}; do \
		$(SED) -i 's/mpack.so/liblua5.'$$ver'-mpack.0.dylib/' $(BUILD_WORK)/libmpack-lua/build5$$ver/Makefile; \
	done
	$(SED) -i 's/mpack.so/libluajit-5.1-mpack.0.dylib/' $(BUILD_WORK)/libmpack-lua/buildjit/Makefile
	mkdir -p $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

ifneq ($(wildcard $(BUILD_WORK)/libmpack-lua/.build_complete),)
libmpack-lua:
	@echo "Using previously built libmpack-lua."
else
libmpack-lua: libmpack-lua-setup libmpack lua5.1 lua5.2 lua5.3 luajit
	for ver in {1..3}; do \
		$(MAKE) -C $(BUILD_WORK)/libmpack-lua/build5$$ver install \
			USE_SYSTEM_MPACK=1 \
			MPACK_LUA_VERSION=5.$$ver \
			LUA_INCLUDE="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			LIBS=-llua5.$$ver\ -lmpack \
			LUA_CMOD_INSTALLDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
			DESTDIR=$(BUILD_STAGE)/libmpack-lua; \
		$(MAKE) -C $(BUILD_WORK)/libmpack-lua/build5$$ver/bundle install \
			USE_SYSTEM_MPACK=1 \
			MPACK_LUA_VERSION=5.$$ver \
			LUA_INCLUDE="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			LDFLAGS="$(LDFLAGS) -undefined suppress -undefined dynamic_lookup" \
			LUA_CMOD_INSTALLDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver \
			DESTDIR=$(BUILD_STAGE)/libmpack-lua; \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-mpack.0.dylib $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-mpack.0.dylib; \
		$(LN) -sf liblua5.$$ver-mpack.0.dylib $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-mpack.dylib; \
	done
	$(MAKE) -C $(BUILD_WORK)/libmpack-lua/buildjit install \
		USE_SYSTEM_MPACK=1 \
		MPACK_LUA_VERSION=5.1 \
		LUA_INCLUDE="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1" \
		LIBS=-lluajit-5.1\ -lmpack \
		LUA_CMOD_INSTALLDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		DESTDIR=$(BUILD_STAGE)/libmpack-lua
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-mpack.0.dylib $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-mpack.0.dylib
	$(LN) -sf libluajit-5.1-mpack.0.dylib $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-mpack.dylib
	touch $(BUILD_WORK)/libmpack-lua/.build_complete
endif

libmpack-lua-package: libmpack-lua-stage
	# libmpack-lua.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-mpack
	mkdir -p $(BUILD_DIST)/lua-mpack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpack-lua.mk Prep lua-mpack
	cp -a $(BUILD_STAGE)/libmpack-lua/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblua*5.*-mpack.*.dylib,lua} $(BUILD_DIST)/lua-mpack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpack-lua.mk Sign
	$(call SIGN,lua-mpack,general.xml)

	# libmpack-lua.mk Make .debs
	$(call PACK,lua-mpack,DEB_LIBMPACK-LUA_V)

	# libmpack-lua.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-mpack

.PHONY: libmpack-lua libmpack-lua-package
