ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

zsh:
	cd zsh && LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-cap \
		--enable-maildir-support \
		--enable-multibyte \
		--enable-zsh-secure-free \
		--enable-unicode9 \
		--enable-pcre \
		--with-tcsetpgrp \
		DL_EXT=bundle \
		zsh_cv_rlimit_rss_is_as=yes
	$(MAKE) -C zsh
	$(FAKEROOT) $(MAKE) -C zsh install install.info DESTDIR="$(DESTDIR)"

.PHONY: zsh
