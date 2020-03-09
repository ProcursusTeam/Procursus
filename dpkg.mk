ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

dpkg: setup bash bzip2 coreutils diffutils findutils ncurses tar xz
	if ! [ -f dpkg/configure ]; then \
		cd dpkg && ./autogen; \
	fi
	# autoconf && autoheader && aclocal && automake --add-missing && glibtoolize
	cd dpkg && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--localstatedir=/var \
		--sysconfdir=/etc \
		--disable-start-stop-daemon \
		--disable-dselect \
		USE_NLS=no \
		MAKE=/usr/bin/make \
		PATCH=/usr/bin/patch \
		PERL=/usr/bin/perl \
		TAR=/usr/bin/tar \
		PERL_LIBDIR='$$(prefix)/lib' \
		LZMA_LIBS="-L$(DESTDIR)/usr/lib"
	sed -i -- s/'#define ARCHITECTURE \"darwin-arm\"'/'#define ARCHITECTURE \"$(DEB_ARCH)\"'/ dpkg/config.h
	sed -i -- s/'gtar'/'tar'/ dpkg/config.h
	sed -i '/#include <config.h>/i #include <string.h>\n#include <xlocale.h>' dpkg/lib/dpkg/i18n.c
	$(MAKE) -C dpkg
	$(FAKEROOT) $(MAKE) -C dpkg install DESTDIR="$(DESTDIR)"

.PHONY: dpkg

