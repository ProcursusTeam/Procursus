ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += lua-lpeg
LUA-LPEG_VERSION := 1.0.2
DEB_LUA-LPEG_V   ?= $(LUA-LPEG_VERSION)

lua-lpeg-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-$(LUA-LPEG_VERSION).tar.gz
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build51)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build51/bundle)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build52)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build52/bundle)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build53)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build53/bundle)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/buildjit)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/buildjit/bundle)
	for ver in {1..3}; do \
		$(SED) -i 's/-o lpeg.so/-o liblua5.'$$ver'-lpeg.2.dylib \$$(LDFLAGS) \$$(LIBS)/' $(BUILD_WORK)/lua-lpeg/build5$$ver/makefile; \
		$(SED) -i 's/-o lpeg.so/-o lpeg.so \$$(LDFLAGS)/' $(BUILD_WORK)/lua-lpeg/build5$$ver/bundle/makefile; \
	done
	$(SED) -i 's/-o lpeg.so/-o libluajit-5.1-lpeg.2.dylib \$$(LDFLAGS) \$$(LIBS)/' $(BUILD_WORK)/lua-lpeg/buildjit/makefile
	$(SED) -i 's/-o lpeg.so/-o lpeg.so \$$(LDFLAGS)/' $(BUILD_WORK)/lua-lpeg/buildjit/bundle/makefile
	mkdir -p $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

ifneq ($(wildcard $(BUILD_WORK)/lua-lpeg/.build_complete),)
lua-lpeg:
	@echo "Using previously built lua-lpeg."
else
lua-lpeg: lua-lpeg-setup libuv1 lua5.1 lua5.2 lua5.3 luajit
	for ver in {1..3}; do \
		$(MAKE) -C $(BUILD_WORK)/lua-lpeg/build5$$ver linux \
			LUADIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			LIBS="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver.dylib"; \
		$(MAKE) -C $(BUILD_WORK)/lua-lpeg/build5$$ver/bundle macosx \
			LUADIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver"; \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg.2.dylib; \
		$(LN) -sf liblua5.$$ver-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg.dylib; \
		cp -a $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg*.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
		cp -a $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg*.dylib $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
		mkdir -p $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/; \
		cp -a $(BUILD_WORK)/lua-lpeg/build5$$ver/bundle/lpeg.so $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/; \
	done
	$(MAKE) -C $(BUILD_WORK)/lua-lpeg/buildjit linux \
		LUADIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1" \
		LIBS="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1.dylib"
	$(MAKE) -C $(BUILD_WORK)/lua-lpeg/buildjit/bundle macosx \
		LUADIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1"
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit-5.1-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/buildjit/libluajit-5.1-lpeg.2.dylib
	$(LN) -sf liblua5.1-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/buildjit/libluajit-5.1-lpeg.dylib
	cp -a $(BUILD_WORK)/lua-lpeg/buildjit/libluajit-5.1-lpeg*.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/lua-lpeg/buildjit/libluajit-5.1-lpeg*.dylib $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.1/
	cp -a $(BUILD_WORK)/lua-lpeg/buildjit/bundle/lpeg.so $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.1/
	touch $(BUILD_WORK)/lua-lpeg/.build_complete
endif

lua-lpeg-package: lua-lpeg-stage
	# lua-lpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-lpeg
	mkdir -p $(BUILD_DIST)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-lpeg.mk Prep lua-lpeg
	cp -a $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblua*5.*-lpeg.*.dylib,lua} $(BUILD_DIST)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-lpeg.mk Sign
	$(call SIGN,lua-lpeg,general.xml)

	# lua-lpeg.mk Make .debs
	$(call PACK,lua-lpeg,DEB_LUA-LPEG_V)

	# lua-lpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-lpeg

.PHONY: lua-lpeg lua-lpeg-package
