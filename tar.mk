ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

tar: setup
	cd tar && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		gl_cv_func_ftello_works=yes
	$(MAKE) -C tar
	$(FAKEROOT) $(MAKE) -C tar install

.PHONY: tar
