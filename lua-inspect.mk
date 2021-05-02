ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += lua-inspect
LUA-INSPECT_VERSION := 3.1.1
DEB_LUA-INSPECT_V   ?= $(LUA-INSPECT_VERSION)

lua-inspect-setup: setup
	$(call GITHUB_ARCHIVE,kikito,inspect.lua,$(LUA-INSPECT_VERSION),v$(LUA-INSPECT_VERSION))
	$(call EXTRACT_TAR,inspect.lua-$(LUA-INSPECT_VERSION).tar.gz,inspect.lua-$(LUA-INSPECT_VERSION),lua-inspect)
	mkdir -p $(BUILD_STAGE)/lua-inspect/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lua/5.{1..3}

ifneq ($(wildcard $(BUILD_WORK)/lua-inspect/.build_complete),)
lua-inspect:
	@echo "Using previously built lua-inspect."
else
lua-inspect: lua-inspect-setup
	cp -a $(BUILD_WORK)/lua-inspect/inspect.lua $(BUILD_STAGE)/lua-inspect/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lua/5.1
	cp -a $(BUILD_WORK)/lua-inspect/inspect.lua $(BUILD_STAGE)/lua-inspect/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lua/5.2
	cp -a $(BUILD_WORK)/lua-inspect/inspect.lua $(BUILD_STAGE)/lua-inspect/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lua/5.3
	touch $(BUILD_WORK)/lua-inspect/.build_complete
endif

lua-inspect-package: lua-inspect-stage
	# lua-inspect.mk Package Structure
	rm -rf $(BUILD_DIST)/lua-inspect

	# lua-inspect.mk Prep lua-inspect
	cp -a $(BUILD_STAGE)/lua-inspect $(BUILD_DIST)

	# lua-inspect.mk Make .debs
	$(call PACK,lua-inspect,DEB_LUA-INSPECT_V)

	# lua-inspect.mk Build cleanup
	rm -rf $(BUILD_DIST)/lua-inspect

.PHONY: lua-inspect lua-inspect-package
