ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

ifneq ("$(wildcard $(BUILD_WORK)/dpkg/.build_complete)","")
dpkg:
	@echo "Using previously built dpkg."
else
dpkg: setup bzip2 xz
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
		--with-logdir=/var/log/dpkg \
		--disable-start-stop-daemon \
		--disable-dselect \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		USE_NLS=no \
		PERL_LIBDIR='$$(prefix)/lib' \
		LZMA_LIBS="$(BUILD_BASE)/usr/local/lib/liblzma.a" \
		TAR=$(TAR)
	$(SED) -i s/'#define ARCHITECTURE "darwin-arm64"'/'#define ARCHITECTURE "$(DEB_ARCH)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i s/'#define ARCHITECTURE_OS "darwin"'/'#define ARCHITECTURE_OS "$(PLATFORM)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i '/#include <config.h>/i #include <string.h>\n#include <xlocale.h>' $(BUILD_WORK)/dpkg/lib/dpkg/i18n.c
	$(SED) -i s/'update_dyld_shared_cache'/'launchctl'/ $(BUILD_WORK)/dpkg/src/help.c
	$(SED) -i s/'$(TAR)'/'tar'/ $(BUILD_WORK)/dpkg/config.h
	$(MAKE) -C $(BUILD_WORK)/dpkg
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	$(FAKEROOT) ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg
	touch $(BUILD_WORK)/dpkg/.build_complete
endif

.PHONY: dpkg

