ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

dpkg: setup bash bzip2 zlib coreutils diffutils findutils ncurses tar xz
	if ! [ -f dpkg/configure ]; then \
		cd $(BUILD_WORK)/dpkg && ./autogen; \
	fi
	# autoconf && autoheader && aclocal && automake --add-missing && glibtoolize
	cd $(BUILD_WORK)/dpkg && ./configure -C \
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
		LZMA_LIBS="$(BUILD_BASE)/usr/lib/liblzma.a" \
		ZLIB_LIBS="$(BUILD_STAGE)/zlib/usr/lib/libz.a" \
		TAR=tar
	$(SED) -i s/'#define ARCHITECTURE "darwin-arm64"'/'#define ARCHITECTURE "$(DEB_ARCH)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i s/'#define ARCHITECTURE_OS "darwin"'/'#define ARCHITECTURE_OS "$(PLATFORM)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i '/#include <config.h>/i #include <string.h>\n#include <xlocale.h>' $(BUILD_WORK)/dpkg/lib/dpkg/i18n.c
	$(MAKE) -C $(BUILD_WORK)/dpkg
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	$(FAKEROOT) ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg

.PHONY: dpkg

