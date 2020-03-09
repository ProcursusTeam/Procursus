ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

diffutils: setup
	cd diffutils && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	$(MAKE) -C diffutils
	$(FAKEROOT) $(MAKE) -C diffutils install

.PHONY: diffutils
