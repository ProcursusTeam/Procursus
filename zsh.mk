ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += zsh
DOWNLOAD      += https://www.zsh.org/pub/zsh-$(ZSH_VERSION).tar.xz{,.asc}
ZSH_VERSION   := 5.8
DEB_ZSH_V     ?= $(ZSH_VERSION)

zsh-setup: setup
	$(call EXTRACT_TAR,zsh-$(ZSH_VERSION).tar.xz,zsh-$(ZSH_VERSION),zsh)

ifneq ($(wildcard $(BUILD_WORK)/zsh/.build_complete),)
zsh:
	@echo "Using previously built zsh."
else
zsh: zsh-setup pcre ncurses
	cd $(BUILD_WORK)/zsh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-cap \
		--enable-pcre \
		--enable-multibyte \
		--enable-zsh-secure-free \
		--enable-unicode9 \
		--with-tcsetpgrp \
		--enable-function-subdirs \
		LDFLAGS="$(CFLAGS) -lpcre $(LDFLAGS)" \
		DL_EXT=bundle \
		zsh_cv_rlimit_rss_is_as=yes \
		zsh_cv_path_utmpx=/var/run/utmpx \
		zsh_cv_path_utmp=no
	+$(MAKE) -C $(BUILD_WORK)/zsh
	+$(MAKE) -C $(BUILD_WORK)/zsh install \
		DESTDIR="$(BUILD_STAGE)/zsh"
	rm -f $(BUILD_STAGE)/zsh/usr/bin/zsh-$(ZSH_VERSION)
	touch $(BUILD_WORK)/zsh/.build_complete
endif

zsh-package: zsh-stage
	# zsh.mk Package Structure
	rm -rf $(BUILD_DIST)/zsh
	mkdir -p $(BUILD_DIST)/zsh/bin
	
	# zsh.mk Prep zsh
	$(FAKEROOT) cp -a $(BUILD_STAGE)/zsh/usr $(BUILD_DIST)/zsh
	ln -s ../usr/bin/zsh $(BUILD_DIST)/zsh/bin/zsh
	
	# zsh.mk Sign
	$(call SIGN,zsh,general.xml)
	
	# zsh.mk Make .debs
	$(call PACK,zsh,DEB_ZSH_V)
	
	# zsh.mk Build cleanup
	rm -rf $(BUILD_DIST)/zsh

.PHONY: zsh zsh-package
