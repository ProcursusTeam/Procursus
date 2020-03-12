ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard $(BUILD_WORK)/zsh/.build_complete),)
zsh:
	@echo "Using previously built zsh."
else
zsh: setup pcre ncurses
	cd $(BUILD_WORK)/zsh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-cap \
		--enable-pcre \
		--enable-maildir-support \
		--enable-multibyte \
		--enable-zsh-secure-free \
		--enable-unicode9 \
		--with-tcsetpgrp \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		DL_EXT=bundle \
		zsh_cv_rlimit_rss_is_as=yes
	$(MAKE) -C $(BUILD_WORK)/zsh
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/zsh install install.info \
		DESTDIR="$(BUILD_STAGE)/zsh"
	touch $(BUILD_WORK)/zsh/.build_complete
endif

.PHONY: zsh
