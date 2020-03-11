ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ("$(wildcard uikittools/.build_complete)","")
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: setup
	cd uikittools && make
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/uikittools/usr/bin
	$(FAKEROOT) cp uikittools/{cfversion,sbdidlaunch,sbreload,uicache,uiduid,uiopen} $(BUILD_STAGE)/uikittools/usr/bin
	touch uikittools/.build_complete
endif

.PHONY: uikittools
