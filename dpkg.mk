ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += dpkg
DOWNLOAD       += https://deb.debian.org/debian/pool/main/d/dpkg/dpkg_$(DPKG_VERSION).tar.xz
DPKG_VERSION   := 1.20.0
DEB_DPKG_V     ?= $(DPKG_VERSION)

dpkg-setup: setup
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

.PHONY: dpkg dpkg-package

