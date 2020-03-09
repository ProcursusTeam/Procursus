ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

readline: setup ncurses
	cd readline && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	sed -i s/'#define sig_atomic_t int'// readline/config.h
	$(MAKE) -C readline
	$(FAKEROOT) $(MAKE) -C readline install DESTDIR="$(DESTDIR)"

.PHONY: readline
