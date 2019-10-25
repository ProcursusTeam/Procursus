ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

uikittools:
	cd uikittools && make
	$(FAKEROOT) mkdir -p $(DESTDIR)/usr/bin
	$(FAKEROOT) cp uikittools/{cfversion,sbdidlaunch,sbreload,uicache,uiduid,uiopen} $(DESTDIR)/usr/bin

.PHONY: uikittools
