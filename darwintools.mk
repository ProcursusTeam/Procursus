ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

darwintools:
	cd darwintools && make
	$(FAKEROOT) mkdir -p $(DESTDIR)/usr/bin
	$(FAKEROOT) cp darwintools/sw_vers $(DESTDIR)/usr/bin

.PHONY: darwintools
