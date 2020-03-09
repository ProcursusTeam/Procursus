ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

uikittools: setup
	cd uikittools && make
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/uikittools/usr/bin
	$(FAKEROOT) cp uikittools/{cfversion,sbdidlaunch,sbreload,uicache,uiduid,uiopen} $(BUILD_STAGE)/uikittools/usr/bin

.PHONY: uikittools
