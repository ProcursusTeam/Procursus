ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

xz:
	cd xz && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-silent-rules
	$(MAKE) -C xz
	$(FAKEROOT) $(MAKE) -C xz install DESTDIR="$(DESTDIR)"

.PHONY: xz
