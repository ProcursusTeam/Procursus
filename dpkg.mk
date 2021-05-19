ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += dpkg
DPKG_VERSION   := 1.20.9
DEB_DPKG_V     ?= $(DPKG_VERSION)-1

dpkg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/d/dpkg/dpkg_$(DPKG_VERSION).tar.xz
	$(call EXTRACT_TAR,dpkg_$(DPKG_VERSION).tar.xz,dpkg-$(DPKG_VERSION),dpkg)
	$(call DO_PATCH,dpkg,dpkg,-p1)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,dpkg-ios,dpkg,-p1)

DPKG_LIBS := LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec"
else
	$(call DO_PATCH,dpkg-macos,dpkg,-p1)

DPKG_LIBS :=
endif

ifneq ($(wildcard $(BUILD_WORK)/dpkg/.build_complete),)
dpkg:
	@echo "Using previously built dpkg."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
dpkg: dpkg-setup gettext xz zstd libmd
else
dpkg: dpkg-setup gettext xz zstd libmd libiosexec
	$(SED) -i '/base-bsd-darwin/a base-bsd-darwin-arm64		$(DEB_ARCH)' $(BUILD_WORK)/dpkg/data/tupletable
endif
	cd $(BUILD_WORK)/dpkg && ./autogen
	cd $(BUILD_WORK)/dpkg && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-admindir=$(MEMO_PREFIX)/Library/dpkg \
		--with-logdir=$(MEMO_PREFIX)/var/log \
		--disable-start-stop-daemon \
		--disable-dselect \
		--without-libselinux \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)" \
		PERL_LIBDIR='$$(prefix)/share/perl5' \
		PERL="$(shell which perl)" \
		TAR=$(GNU_PREFIX)tar \
		LZMA_LIBS='$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/liblzma.dylib' \
		$(DPKG_LIBS)
	+$(MAKE) -C $(BUILD_WORK)/dpkg \
		PERL="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl"
	+$(MAKE) -C $(BUILD_WORK)/dpkg install \
		DESTDIR="$(BUILD_STAGE)/dpkg"
	mkdir -p $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)/var/lib
	ln -s /$(MEMO_PREFIX)/Library/dpkg $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)/var/lib/dpkg
	touch $(BUILD_WORK)/dpkg/.build_complete
endif

dpkg-package: dpkg-stage
	# dpkg.mk Package Structure
	rm -rf $(BUILD_DIST)/dpkg{,-dev} $(BUILD_DIST)/libdpkg-perl
	mkdir -p $(BUILD_DIST)/dpkg{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/dpkg} \
		$(BUILD_DIST)/libdpkg-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libdpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# dpkg.mk Prep dpkg
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)/{etc,Library,var} $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{dpkg{,-deb,-divert,-maintscript-helper,-query,-realpath,-split,-statoverride,-trigger},update-alternatives} $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{man,polkit-1,locale} $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -f $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man1/!(dpkg|dpkg-deb|dpkg-divert|dpkg-maintscript-helper|dpkg-query|dpkg-realpath|dpkg-split|dpkg-statoverride|dpkg-trigger|update-alternatives).1
	rm -rf $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man{2..8}
	rm -f $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/*/LC_MESSAGES/!(dpkg.mo)
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dpkg/{{abi,cpu,os,tuple}table,sh} $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dpkg
	mkdir -p $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)/etc/dpkg/origins/
	echo -e "Vendor: Procursus\nVendor-URL: https://github.com/ProcursusTeam/Procursus/\nBugs: mailto://me@diatrus.com" > $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)/etc/dpkg/origins/procursus
	$(LN) -s procursus $(BUILD_DIST)/dpkg/$(MEMO_PREFIX)/etc/dpkg/origins/default

	# dpkg.mk Prep dpkg-dev
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dpkg-{architecture,buildflags,buildpackage,checkbuilddeps,distaddfile,genbuildinfo,genchanges,gencontrol,gensymbols,mergechangelogs,name,parsechangelog,scanpackages,scansources,shlibdeps,source,vendor} $(BUILD_DIST)/dpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dpkg/*.mk $(BUILD_DIST)/dpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dpkg
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/dpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -f $(BUILD_DIST)/dpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man1/!(dpkg-architecture|dpkg-buildflags|dpkg-buildpacke|dpkg-checkbuilddeps|dpkg-distaddfile|dpkg-genbuildinfo|dpkg-genchanges|dpkg-gencontrol|dpkg-gensymbols|dpkg-mergechangelogs|dpkg-name|dpkg-parsechangelog|dpkg-scanpackages|dpkg-scansources|dpkg-shlibdeps|dpkg-source|dpkg-vendor).1
	rm -rf $(BUILD_DIST)/dpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man{3,8}

	# dpkg.mk Prep libdpkg-perl
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,perl5} $(BUILD_DIST)/libdpkg-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -f $(BUILD_DIST)/libdpkg-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/*/LC_MESSAGES/!(dpkg-dev.mo)
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libdpkg-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# dpkg.mk Prep libdpkg-dev
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/dpkg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libdpkg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

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

