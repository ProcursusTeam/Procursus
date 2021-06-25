ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += vim
# Per homebrew, vim should only be updated every 50 releases on multiples of 50
VIM_VERSION := 8.2.1800
DEB_VIM_V   ?= $(VIM_VERSION)

vim-setup: setup
	$(call GITHUB_ARCHIVE,vim,vim,$(VIM_VERSION),v$(VIM_VERSION))
	$(call EXTRACT_TAR,vim-$(VIM_VERSION).tar.gz,vim-$(VIM_VERSION),vim)

ifneq ($(wildcard $(BUILD_WORK)/vim/.build_complete),)
vim:
	@echo "Using previously built vim."
else
vim: .SHELLFLAGS=-O extglob -c
vim: vim-setup ncurses gettext
	$(SED) -i 's/AC_TRY_LINK(\[]/AC_TRY_LINK(\[#include <termcap.h>]/g' $(BUILD_WORK)/vim/src/configure.ac # This is so stupid, I cannot believe this is necessary.
	cd $(BUILD_WORK)/vim/src && autoconf -f
	cd $(BUILD_WORK)/vim && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-gui=no \
		--with-tlib=ncursesw \
		--without-x \
		--disable-darwin \
		vim_cv_toupper_broken=no \
		vim_cv_terminfo=yes \
		vim_cv_tgetent=zero \
		vim_cv_tty_group=4 \
		vim_cv_tty_mode=0620 \
		vim_cv_getcwd_broken=no \
		vim_cv_stat_ignores_slash=no \
		vim_cv_memmove_handles_overlap=yes
	+$(MAKE) -C $(BUILD_WORK)/vim
	+$(MAKE) -C $(BUILD_WORK)/vim install \
		DESTDIR="$(BUILD_STAGE)/vim"
	rm -f $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(vim|vimtutor|xxd)
	mv $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vim $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vim.basic
	rm -rf $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*{ISO*,UTF*,KOI*}
	find $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f ! -name "vim.1" ! -name "vimtutor.1" ! -name "xxd.1" -delete
	find $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type l -delete
	touch $(BUILD_WORK)/vim/.build_complete
endif
vim-package: vim-stage
	# vim.mk Package Structure
	rm -rf $(BUILD_DIST)/{vim,xxd}
	mkdir -p $(BUILD_DIST)/{vim,xxd}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share}

	# vim.mk Prep vim
	cp -a $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vim{.basic,tutor} $(BUILD_DIST)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{vim,man} $(BUILD_DIST)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	find $(BUILD_DIST)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f -name "xxd.1" -delete

	# vim.mk Prep xxd
	cp -a $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xxd $(BUILD_DIST)/xxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/vim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/xxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	find $(BUILD_DIST)/xxd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man -type f ! -name "xxd.1" -delete

	# vim.mk Sign
	$(call SIGN,vim,general.xml)
	$(call SIGN,xxd,general.xml)

	# vim.mk Make .debs
	$(call PACK,vim,DEB_VIM_V)
	$(call PACK,xxd,DEB_VIM_V)

	# vim.mk Build cleanup
	rm -rf $(BUILD_DIST)/{vim,xxd}

.PHONY: vim vim-package
