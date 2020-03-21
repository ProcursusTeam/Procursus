ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DPKG_VERSION := 1.20.0
DEB_DPKG_V   ?= $(DPKG_VERSION)

ifneq ($(wildcard dpkg/.build_complete),)
dpkg:
	@echo "Using previously built dpkg."
else
dpkg: setup xz
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
		--with-logdir=/var/log/dpkg \
		--disable-start-stop-daemon \
		--disable-dselect \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		USE_NLS=no \
		PERL_LIBDIR='$$(prefix)/lib' \
		TAR=$(TAR)
	$(MAKE) -C dpkg \
		ARCHITECTURE=$(DEB_ARCH) \
		ARCHITECTURE_OS=$(PLATFORM) \
		TAR=tar
	$(FAKEROOT) $(MAKE) -C dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	$(FAKEROOT) ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg
	touch dpkg/.build_complete
endif

.PHONY: dpkg

