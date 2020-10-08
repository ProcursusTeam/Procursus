ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += dpkg
DPKG_VERSION   := 1.20.5
DEB_DPKG_V     ?= $(DPKG_VERSION)-3

dpkg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/d/dpkg/dpkg_$(DPKG_VERSION).tar.xz
	$(call EXTRACT_TAR,dpkg_$(DPKG_VERSION).tar.xz,dpkg-$(DPKG_VERSION),dpkg)
	$(call DO_PATCH,dpkg,dpkg,-p1)

ifneq ($(wildcard $(BUILD_WORK)/dpkg/.build_complete),)
dpkg:
	@echo "Using previously built dpkg."
else
dpkg: dpkg-setup gettext xz zstd
	$(SED) -i '/base-bsd-darwin/a base-bsd-darwin-arm64		$(DEB_ARCH) \
base-bsd-darwin-arm		$(DEB_ARCH) \
base-bsd-darwin-armk		$(DEB_ARCH)' $(BUILD_WORK)/dpkg/data/tupletable
	if ! [ -f $(BUILD_WORK)/dpkg/configure ]; then \
		cd $(BUILD_WORK)/dpkg && ./autogen; \
	fi
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
		PERL_LIBDIR='$$(prefix)/share/perl5' \
		PERL="/usr/bin/perl" \
		TAR=tar \
		LZMA_LIBS='$(BUILD_BASE)/usr/local/lib/liblzma.dylib'
	+$(MAKE) -C $(BUILD_WORK)/dpkg
	+$(MAKE) -C $(BUILD_WORK)/dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	mkdir -p $(BUILD_STAGE)/dpkg/var/lib
	ln -s /Library/dpkg $(BUILD_STAGE)/dpkg/var/lib/dpkg
	touch $(BUILD_WORK)/dpkg/.build_complete
endif

dpkg-package: dpkg-stage
	# dpkg.mk Package Structure
	rm -rf $(BUILD_DIST)/dpkg{,-dev} $(BUILD_DIST)/libdpkg-perl
	mkdir -p $(BUILD_DIST)/dpkg{,-dev}/usr/{bin,share/dpkg} \
		$(BUILD_DIST)/libdpkg-perl/usr/share/locale/{ca,de,es,fr,pl,ru,sv}/LC_MESSAGES \
		$(BUILD_DIST)/libdpkg-dev/usr
	
	# dpkg.mk Prep DPKG
	cp -a $(BUILD_STAGE)/dpkg/{etc,Library,var} $(BUILD_DIST)/dpkg
	cp -a $(BUILD_STAGE)/dpkg/usr/bin/{dpkg{,-deb,-divert,-maintscript-helper,-query,-realpath,-split,-statoverride,-trigger},update-alternatives} $(BUILD_DIST)/dpkg/usr/bin
	cp -a $(BUILD_STAGE)/dpkg/usr/share/{man,polkit-1,locale} $(BUILD_DIST)/dpkg/usr/share
	rm -f $(BUILD_DIST)/dpkg/usr/share/locale/*/LC_MESSAGES/dpkg-dev.mo
	cp -a $(BUILD_STAGE)/dpkg/usr/share/dpkg/{{abi,cpu,os,tuple}table,sh} $(BUILD_DIST)/dpkg/usr/share/dpkg
	
	# dpkg.mk Prep DPKG-Dev
	cp -a $(BUILD_STAGE)/dpkg/usr/bin/dpkg-{architecture,buildflags,buildpackage,checkbuilddeps,distaddfile,genbuildinfo,genchanges,gencontrol,gensymbols,mergechangelogs,name,parsechangelog,scanpackages,scansources,shlibdeps,source,vendor} $(BUILD_DIST)/dpkg-dev/usr/bin
	cp -a $(BUILD_STAGE)/dpkg/usr/share/dpkg/*.mk $(BUILD_DIST)/dpkg-dev/usr/share/dpkg
	
	# dpkg.mk Prep libdpkg-perl
	cp -a $(BUILD_STAGE)/dpkg/usr/share/perl5 $(BUILD_DIST)/libdpkg-perl/usr/share
	for locale in ca de es fr pl ru sv; do \
		cp -a $(BUILD_STAGE)/dpkg/usr/share/locale/$$locale/LC_MESSAGES/dpkg-dev.mo $(BUILD_DIST)/libdpkg-perl/usr/share/locale/$$locale/LC_MESSAGES; \
	done
	
	# dpkg.mk Prep libdpkg-dev
	cp -a $(BUILD_STAGE)/dpkg/usr/include $(BUILD_DIST)/libdpkg-dev/usr
	cp -a $(BUILD_STAGE)/dpkg/usr/lib $(BUILD_DIST)/libdpkg-dev/usr
	
	# dpkg.mk Sign
	$(call SIGN,dpkg,general.xml)
	
	# dpkg.mk Make .debs
	$(call PACK,dpkg,DEB_DPKG_V)
	$(call PACK,dpkg-dev,DEB_DPKG_V)
	$(call PACK,libdpkg-perl,DEB_DPKG_V)
	$(call PACK,libdpkg-dev,DEB_DPKG_V)
	
	# dpkg.mk Build cleanup
	rm -rf $(BUILD_DIST)/dpkg{,-dev} $(BUILD_DIST)/libdpkg-{dev,perl}

.PHONY: dpkg dpkg-package

