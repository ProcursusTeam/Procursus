ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

findutils: setup
	cd $(BUILD_WORK)/findutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-debug \
		gl_cv_func_ftello_works=yes
	$(MAKE) -C $(BUILD_WORK)/findutils
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/findutils install \
		DESTDIR=$(BUILD_STAGE)/findutils

.PHONY: findutils
