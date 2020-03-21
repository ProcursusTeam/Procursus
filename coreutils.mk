ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

COREUTILS_VERSION := 8.31
DEB_COREUTILS_V   ?= $(COREUTILS_VERSION)

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils:
	@echo "Using previously built coreutils."
else
coreutils: setup
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-gmp \
		gl_cv_func_ftello_works=yes
	$(MAKE) -C $(BUILD_WORK)/coreutils
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	touch $(BUILD_WORK)/coreutils/.build_complete
endif

.PHONY: coreutils
