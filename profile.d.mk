ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

PROFILED_VERSION := 1
DEB_PROFILED_V   ?= $(PROFILED_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/profile.d/.build_complete),)
profile.d:
	@echo "Using previously built profile.d."
else
profile.d: setup
	cd darwintools && make
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/darwintools/usr/bin
	$(FAKEROOT) cp darwintools/sw_vers $(BUILD_STAGE)/darwintools/usr/bin
	touch darwintools/.build_complete
endif

.PHONY: darwintools
