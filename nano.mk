ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

nano:
	cd nano && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug
		--disable-dependency-tracking \
		--enable-color \
		--enable-extra \
		--enable-multibuffer \
		--enable-nanorc \
		--enable-utf8
	$(MAKE) -C nano DESTDIR="$(DESTDIR)"
	$(FAKEROOT) $(MAKE) -C nano install DESTDIR="$(DESTDIR)"

.PHONY: nano
