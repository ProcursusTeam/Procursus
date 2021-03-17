ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += lua-lpeg
LUA-LPEG_VERSION := 1.0.2
DEB_LUA-LPEG_V   ?= $(LUA-LPEG_VERSION)

lua-lpeg-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-$(LUA-LPEG_VERSION).tar.gz
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build51)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build52)
	$(call EXTRACT_TAR,lpeg-$(LUA-LPEG_VERSION).tar.gz,lpeg-$(LUA-LPEG_VERSION),lua-lpeg/build53)
	for ver in {1..3}; do \
		$(SED) -i 's/-o lpeg.so/-o liblua5.'$$ver'-lpeg.2.dylib \$$(LIBS)/' $(BUILD_WORK)/lua-lpeg/build5$$ver/makefile; \
	done
	mkdir -p $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

ifneq ($(wildcard $(BUILD_WORK)/lua-lpeg/.build_complete),)
lua-lpeg:
	@echo "Using previously built lua-lpeg."
else
lua-lpeg: lua-lpeg-setup libuv1 lua5.1 lua5.2 lua5.3
	for ver in {1..3}; do \
		$(MAKE) -C $(BUILD_WORK)/lua-lpeg/build5$$ver linux \
			LUADIR="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver" \
			LIBS="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver.dylib"; \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblua5.$$ver-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg.2.dylib; \
		$(LN) -sf liblua5.$$ver-lpeg.2.dylib $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg.dylib; \
		cp -a $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg*.dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
		cp -a $(BUILD_WORK)/lua-lpeg/build5$$ver/liblua5.$$ver-lpeg*.dylib $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
		mkdir -p $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/; \
		$(LN) -sf ../../liblua5.$$ver-lpeg.2.dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/lpeg.so; \
		mkdir -p $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/; \
		$(LN) -sf ../../liblua5.$$ver-lpeg.2.dylib $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/lpeg.so; \
	done
	touch $(BUILD_WORK)/lua-lpeg/.build_complete
endif

lua-lpeg-package: lua-lpeg-stage
	# lua-lpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-lpeg
	mkdir -p $(BUILD_DIST)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# lua-lpeg.mk Prep lua-lpeg
	cp -a $(BUILD_STAGE)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblua5.*-lpeg.*.dylib,lua} $(BUILD_DIST)/lua-lpeg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-lpeg.mk Sign
	$(call SIGN,lua-lpeg,general.xml)
	
	# lua-lpeg.mk Make .debs
	$(call PACK,lua-lpeg,DEB_LUA-LPEG_V)
	
	# lua-lpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-lpeg

.PHONY: lua-lpeg lua-lpeg-package
