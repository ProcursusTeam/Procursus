ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

zlib:
	cd zlib && ./configure \
		--prefix=/usr
	$(MAKE) -C zlib
	$(FAKEROOT) $(MAKE) -C zlib install

.PHONY: zlib
