ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/sed/.build_complete),)
sed:
	@echo "Using previously built sed."
else
sed: setup
	cd $(BUILD_WORK)/sed && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		gl_cv_func_ftello_works=yes
	$(MAKE) -C $(BUILD_WORK)/sed
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/sed install \
		DESTDIR=$(BUILD_STAGE)/sed
	touch $(BUILD_WORK)/sed/.build_complete
endif

.PHONY: sed
