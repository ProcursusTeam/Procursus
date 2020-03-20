ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DARWINTOOLS_VERSION := 1

ifneq ($(wildcard darwintools/.build_complete),)
darwintools:
	@echo "Using previously built darwintools."
else
darwintools: setup
	cd darwintools && make
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/darwintools/usr/bin
	$(FAKEROOT) cp darwintools/sw_vers $(BUILD_STAGE)/darwintools/usr/bin
	touch darwintools/.build_complete
endif

.PHONY: darwintools
