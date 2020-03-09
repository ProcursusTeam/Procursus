ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

zsh: setup
	cd $(BUILD_WORK)/zsh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-cap \
		--enable-maildir-support \
		--enable-multibyte \
		--enable-zsh-secure-free \
		--enable-unicode9 \
		--enable-pcre \
		--with-tcsetpgrp \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		DL_EXT=bundle \
		zsh_cv_rlimit_rss_is_as=yes
	$(MAKE) -C $(BUILD_WORK)/zsh
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/zsh install install.info \
		DESTDIR="$(BUILD_STAGE)/zsh"

.PHONY: zsh
