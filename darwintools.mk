ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

darwintools: setup
	cd darwintools && make
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/darwintools/usr/bin
	$(FAKEROOT) cp darwintools/sw_vers $(BUILD_STAGE)/darwintools/usr/bin

.PHONY: darwintools
