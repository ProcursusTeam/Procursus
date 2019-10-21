ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# Needs DESTDIR in make -j8 to not attempt to build test files (which fail to link)
# May need the make clean in between to keep out artifacts from the old DESTDIR

ncurses:
	if [ -f ncurses/Makefile ]; then \
		$(MAKE) -C ncurses clean; \
	else \
		:; \
	fi
	cd ncurses && LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--libdir=/usr/local/lib \
		--with-build-cc=clang \
		--enable-pc-files \
		--enable-sigwinch \
		--enable-symlinks \
		--enable-widec \
		--with-shared \
		--with-gpm=no
	$(MAKE) -C ncurses DESTDIR="$(DESTDIR)"
	$(FAKEROOT) $(MAKE) -C ncurses install DESTDIR="$(DESTDIR)"

.PHONY: ncurses
