ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DPKG_VERSION := 1.20.0
DEB_DPKG_V   ?= $(DPKG_VERSION)

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

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
		PERL_LIBDIR='$$(prefix)/share/perl5' \
		TAR=$(TAR) \
		LZMA_LIBS=$(BUILD_BASE)/usr/local/lib/liblzma.5.dylib 
	$(SED) -i s/'#define ARCHITECTURE "darwin-arm64"'/'#define ARCHITECTURE "$(DEB_ARCH)"'/ dpkg/config.h
	$(SED) -i s/'#define ARCHITECTURE_OS "darwin"'/'#define ARCHITECTURE_OS "$(PLATFORM)"'/ dpkg/config.h
	$(SED) -i s/'$(TAR)'/'tar'/ dpkg/config.h
	$(MAKE) -C dpkg
	$(FAKEROOT) $(MAKE) -C dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	$(FAKEROOT) ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg
	touch dpkg/.build_complete
endif

dpkg-stage:
	# dpkg.mk Package Structure
	rm -rf $(BUILD_DIST)/dpkg{,-dev}
	mkdir -p $(BUILD_DIST)/dpkg{,-dev}/usr/{bin,share/dpkg}
	
	# dpkg.mk Prep DPKG
	cp -a $(BUILD_STAGE)/dpkg/{etc,Library,var} $(BUILD_DIST)/dpkg
	cp -a $(BUILD_STAGE)/dpkg/usr/bin/{dpkg{,-deb,-divert,-maintscript-helper,-query,-split,-statoverride,-trigger},update-alternatives} $(BUILD_DIST)/dpkg/usr/bin
	cp -a $(BUILD_STAGE)/dpkg/usr/share/polkit-1 $(BUILD_DIST)/dpkg/usr/share
	cp -a $(BUILD_STAGE)/dpkg/usr/share/dpkg/{abi,cpu,os,tuple}table $(BUILD_DIST)/dpkg/usr/share/dpkg
	
	# dpkg.mk Prep DPKG-Dev
	cp -a $(BUILD_STAGE)/dpkg/usr/bin/dpkg-{architecture,buildflags,buildpackage,checkbuilddeps,distaddfile,genbuildinfo,genchanges,gencontrol,gensymbols,mergechangelogs,name,parsechangelog,scanpackages,scansources,shlibdeps,source,vendor} $(BUILD_DIST)/dpkg-dev/usr/bin
	cp -a $(BUILD_STAGE)/dpkg/usr/lib $(BUILD_DIST)/dpkg-dev/usr
	cp -a $(BUILD_STAGE)/dpkg/usr/share/perl5 $(BUILD_DIST)/dpkg-dev/usr/share
	cp -a $(BUILD_STAGE)/dpkg/usr/share/dpkg/*.mk $(BUILD_DIST)/dpkg-dev/usr/share/dpkg
	
	#dpkg.mk Sign
	$(call SIGN,dpkg,general.xml)
	
	# dpkg.mk Make .debs
	$(call PACK,dpkg,DEB_DPKG_V)
	$(call PACK,dpkg-dev,DEB_DPKG_V)
	
	# dpkg.mk Build cleanup
	rm -rf $(BUILD_DIST)/dpkg{,-dev}

.PHONY: dpkg

