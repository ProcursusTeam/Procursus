ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += dpkg
DOWNLOAD       += https://deb.debian.org/debian/pool/main/d/dpkg/dpkg_$(DPKG_VERSION).tar.xz
DPKG_VERSION   := 1.20.0
DEB_DPKG_V     ?= $(DPKG_VERSION)

dpkg-setup: setup
	$(call EXTRACT_TAR,dpkg_$(DPKG_VERSION).tar.xz,dpkg-$(DPKG_VERSION),dpkg)
	mkdir -p $(BUILD_WORK)/dpkg-$(DPKG_VERSION)-patches
	wget -q -O $(BUILD_WORK)/dpkg-$(DPKG_VERSION)-patches/zstd.patch \
		'https://bugs.debian.org/cgi-bin/bugreport.cgi?att=1;bug=892664;filename=0001-dpkg-Add-Zstandard-compression-and-decompression-sup.patch;msg=20'
	$(call DO_PATCH,dpkg-$(DPKG_VERSION),dpkg,-p1)

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

ifneq ($(wildcard $(BUILD_WORK)/dpkg/.build_complete),)
dpkg:
	@echo "Using previously built dpkg."
else
dpkg: dpkg-setup gettext xz zstd
	# Ugliness to avoid using a git submodule
	$(SED) -i '/PREINSTFILE/a #define EXTRAINSTFILE      \"extrainst_\"' $(BUILD_WORK)/dpkg/lib/dpkg/dpkg.h
	$(SED) -i '/tar_deferred_extract/a \	if (oldversionstatus == PKG_STAT_NOTINSTALLED || oldversionstatus == PKG_STAT_CONFIGFILES) { \
    maintscript_new(pkg, EXTRAINSTFILE, "extra-installation", cidir, cidirrest, \
                    "install", NULL); \
  } else { \
    maintscript_new(pkg, EXTRAINSTFILE, "extra-installation", cidir, cidirrest, \
                    "upgrade", \
                    versiondescribe(&pkg->installed.version, vdew_nonambig), \
                    NULL); \
  }' $(BUILD_WORK)/dpkg/src/unpack.c
	$(SED) -i '/update_dyld_shared_cache/d' $(BUILD_WORK)/dpkg/src/help.c
	$(SED) -i '/i18n.h/a #ifdef __APPLE__ \
#include <string.h> \
#include <xlocale.h> \
#endif' $(BUILD_WORK)/dpkg/lib/dpkg/i18n.c
	$(SED) -i '/config.h/i #include <sys/errno.h>' $(BUILD_WORK)/dpkg/lib/dpkg/command.c
	$(SED) -i 's/ohshite(_("unable to execute %s (%s)"), cmd->name, cmd->filename);/if (errno == EPERM || errno == ENOEXEC) { \
\		const char *shell; \
\		if (access(DEFAULTSHELL, X_OK) == 0) { \
\			shell = DEFAULTSHELL; \
\		} else if (access("\/etc\/alternatives\/sh", X_OK) == 0) { \
\			shell = "\/etc\/alternatives\/sh"; \
\		} else if (access("\/bin\/bash", X_OK) == 0) { \
\			shell = "\/bin\/bash"; \
\		} else { \
\			ohshite(_("unable to execute %s (%s): no shell!"), cmd->name, cmd->filename); \
\		} \
\		struct command newcmd; \
\		command_init(\&newcmd, shell, NULL); \
\		command_add_args(\&newcmd, shell, "-c", "\\"$$0\\" \\"$$@\\"", NULL); \
\		command_add_argl(\&newcmd, cmd->argv); \
\		execvp(shell, (char * const *)newcmd.argv); \
\		& \
\	}/' $(BUILD_WORK)/dpkg/lib/dpkg/command.c

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
		TAR=$(TAR)
	$(SED) -i s/'#define ARCHITECTURE "darwin-arm64"'/'#define ARCHITECTURE "$(DEB_ARCH)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i s/'#define ARCHITECTURE_OS "darwin"'/'#define ARCHITECTURE_OS "$(PLATFORM)"'/ $(BUILD_WORK)/dpkg/config.h
	$(SED) -i s/'$(TAR)'/'tar'/ $(BUILD_WORK)/dpkg/config.h
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

