ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += neovim
NEOVIM_VERSION := 0.9.0
DEB_NEOVIM_V   ?= $(NEOVIM_VERSION)

neovim-setup: setup
	$(call GITHUB_ARCHIVE,neovim,neovim,v$(NEOVIM_VERSION),v$(NEOVIM_VERSION))
	$(call EXTRACT_TAR,neovim-v$(NEOVIM_VERSION).tar.gz,neovim-$(NEOVIM_VERSION),neovim)
	$(call DO_PATCH,neovim,neovim,-p1)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,neovim-ios,neovim,-p1)
endif
	mkdir -p $(BUILD_WORK)/neovim/build
	# This is needed to fix a strange linking error. A better fix would be nice.
	test -f $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit5.1-luv.dylib || $(LN_S) libluajit-5.1-luv.dylib $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit5.1-luv.dylib
ifneq ($(call HAS_COMMAND,nvim),1)
neovim:
	@echo "Install neovim before building"
else ifneq ($(wildcard $(BUILD_WORK)/neovim/.build_complete),)
neovim:
	@echo "Using previously built neovim."
else
neovim: neovim-setup gettext lua-luv libuv1 msgpack libvterm libtermkey unibilium luajit tree-sitter libmpack-lua lua-lpeg
	@echo "Install neovim before building"
	cd $(BUILD_WORK)/neovim/build && $(MEMO_DEPLOYMENT) cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DXGETTEXT_PRG="`which xgettext`" \
		-DLUA_PRG="`which luajit`" \
		-DGETTEXT_MSGFMT_EXECUTABLE="`which msgfmt`" \
		-DGETTEXT_MSGMERGE_EXECUTABLE="`which msgmerge`" \
		-DLIBLUV_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libluajit5.1-luv.dylib" \
		-DLIBLUV_INCLUDE_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/lua5.1/" \
		-DCMAKE_BUILD_RPATH="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		..
	+$(MAKE) -C $(BUILD_WORK)/neovim/build
	+$(MAKE) -C $(BUILD_WORK)/neovim/build install \
		DESTDIR="$(BUILD_STAGE)/neovim"
	$(call AFTER_BUILD)
endif

neovim-package: neovim-stage
	# neovim.mk Package Structure
	rm -rf $(BUILD_DIST)/neovim

	# neovim.mk Prep neovim
	cp -a $(BUILD_STAGE)/neovim $(BUILD_DIST)
	for i in ex rview rvim view vimdiff; do \
	install -Dm0755 $(BUILD_MISC)/neovim/$$i $(BUILD_DIST)/neovim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neovim/$$i; \
	sed -i 's|usr/bin/nvim|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/nvim|g' $(BUILD_DIST)/neovim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neovim/$$i; \
	done

	# neovim.mk Sign
	$(call SIGN,neovim,general.xml)

	# neovim.mk Make .debs
	$(call PACK,neovim,DEB_NEOVIM_V)

	# neovim.mk Build cleanup
	rm -rf $(BUILD_DIST)/neovim

.PHONY: neovim neovim-package
