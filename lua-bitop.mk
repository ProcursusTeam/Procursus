ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += lua-bitop
LUA-BITOP_VERSION := 1.0.2
DEB_LUA-BITOP_V   ?= $(LUA-BITOP_VERSION)

lua-bitop-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://bitop.luajit.org/download/LuaBitOp-$(LUA-BITOP_VERSION).tar.gz
	$(call EXTRACT_TAR,LuaBitOp-$(LUA-BITOP_VERSION).tar.gz,LuaBitOp-$(LUA-BITOP_VERSION),lua-bitop)
	mkdir -p $(BUILD_STAGE)/lua-bitop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/{5.1,5.2}

ifneq ($(wildcard $(BUILD_WORK)/lua-bitop/.build_complete),)
lua-bitop:
	@echo "Using previously built lua-bitop."
else
lua-bitop: lua-bitop-setup libuv1 lua5.1 lua5.2 luajit
	for ver in {1..2}; do \
			$(CC) $(CFLAGS) -shared $(LDFLAGS) $(BUILD_WORK)/lua-bitop/bit.c -install_name $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/bit.so\
				-I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.$$ver -llua5.$$ver \
				-o $(BUILD_STAGE)/lua-bitop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lua/5.$$ver/bit.so; \
	done
	touch $(BUILD_WORK)/lua-bitop/.build_complete
endif

lua-bitop-package: lua-bitop-stage
	# lua-bitop.mk Package Structure
	mkdir -p $(BUILD_DIST)/lua-bitop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lua-bitop.mk Prep lua-bitop
	cp -a $(BUILD_STAGE)/lua-bitop $(BUILD_DIST)

	# lua-bit.mk Sign
	$(call SIGN,lua-bitop,general.xml)

	# lua-bit.mk Make .debs
	$(call PACK,lua-bitop,DEB_LUA-BITOP_V)

	# lua-bit.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-bitop

.PHONY: lua-bitop lua-bitop-package
