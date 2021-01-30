ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += neovim
NEOVIM_VERSION := 0.4.4
DEB_NEOVIM_V   ?= $(NEOVIM_VERSION)

neovim-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/neovim-$(NEOVIM_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/neovim-$(NEOVIM_VERSION).tar.gz \
			https://github.com/neovim/neovim/archive/v$(NEOVIM_VERSION).tar.gz
	$(call EXTRACT_TAR,neovim-$(NEOVIM_VERSION).tar.gz,neovim-$(NEOVIM_VERSION),neovim)
	$(call DO_PATCH,neovim,neovim,-p1)
	mkdir -p $(BUILD_WORK)/neovim/build
	@echo "If this fails, run \`eval \$$(luarocks path --lua-dir=[path-to-luadir])\` --bin)"

ifneq ($(call HAS_COMMAND,nvim),1)
neovim:
	@echo "Install neovim before building"
else ifneq ($(wildcard $(BUILD_WORK)/neovim/.build_complete),)
neovim:
	@echo "Using previously built neovim."
else
neovim: neovim-setup gettext lua-luv libuv1 msgpack libvterm libtermkey unibilium luajit
	@echo "Install neovim before building"
	cd $(BUILD_WORK)/neovim/build && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DXGETTEXT_PRG="`which xgettext`" \
		-DGETTEXT_MSGFMT_EXECUTABLE="`which msgfmt`" \
		-DGETTEXT_MSGMERGE_EXECUTABLE="`which msgmerge`" \
		-DLIBLUV_LIBRARY="$(BUILD_BASE)/usr/lib/liblua5.1-luv.dylib" \
		-DLIBLUV_INCLUDE_DIR="$(BUILD_BASE)/usr/include/lua5.1/" \
		..
	+$(MAKE) -C $(BUILD_WORK)/neovim/build
	+$(MAKE) -C $(BUILD_WORK)/neovim/build install \
		DESTDIR="$(BUILD_STAGE)/neovim"
	touch $(BUILD_WORK)/neovim/.build_complete
endif

neovim-package: neovim-stage
	# neovim.mk Package Structure
	rm -rf $(BUILD_DIST)/neovim
	
	# neovim.mk Prep neovim
	cp -a $(BUILD_STAGE)/neovim $(BUILD_DIST)/neovim
	for i in ex rview rvim view vimdiff; do \
	$(GINSTALL) -Dm0755 $(BUILD_INFO)/neovim.$$i $(BUILD_DIST)/neovim/usr/libexec/neovim/$$i; \
	done
	
	# neovim.mk Sign
	$(call SIGN,neovim,general.xml)
	
	# neovim.mk Make .debs
	$(call PACK,neovim,DEB_NEOVIM_V)
	
	# neovim.mk Build cleanup
	rm -rf $(BUILD_DIST)/neovim

.PHONY: neovim neovim-package
