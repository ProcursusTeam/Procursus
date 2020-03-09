ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

dpkg: setup bash bzip2 coreutils diffutils findutils ncurses tar xz
	if ! [ -f dpkg/configure ]; then \
		cd dpkg && ./autogen; \
	fi
	# autoconf && autoheader && aclocal && automake --add-missing && glibtoolize
	cd dpkg && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--localstatedir=/var \
		--sysconfdir=/etc \
		--with-admindir=/Library/dpkg \
		--disable-start-stop-daemon \
		--disable-dselect \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		USE_NLS=no \
		PERL_LIBDIR='$$(prefix)/lib' \
		LZMA_LIBS="$(BUILD_BASE)/usr/local/lib/liblzma.a" \
		TAR=tar
	sed -i s/'#define ARCHITECTURE "darwin-arm64"'/'#define ARCHITECTURE "$(DEB_ARCH)"'/ dpkg/config.h
	sed -i s/'#define ARCHITECTURE_OS "darwin"'/'#define ARCHITECTURE_OS "$(PLATFORM)"'/ dpkg/config.h
	sed -i '/#include <config.h>/i #include <string.h>\n#include <xlocale.h>' dpkg/lib/dpkg/i18n.c
	$(MAKE) -C dpkg
	$(FAKEROOT) $(MAKE) -C dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	$(FAKEROOT) ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg

.PHONY: dpkg

