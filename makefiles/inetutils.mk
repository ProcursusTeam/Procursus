ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += inetutils
INETUTILS_VERSION  := 2.0
DEB_INETUTILS_V    ?= $(INETUTILS_VERSION)-1
DEBIAN_INETUTILS_V := 2.2-2
inetutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/inetutils/inetutils-$(INETUTILS_VERSION).tar.xz{,.sig} \
	https://deb.debian.org/debian/pool/main/i/inetutils/inetutils_$(DEBIAN_INETUTILS_V).debian.tar.xz
	$(call PGP_VERIFY,inetutils-$(INETUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,inetutils-$(INETUTILS_VERSION).tar.xz,inetutils-$(INETUTILS_VERSION),inetutils)
	$(call EXTRACT_TAR,inetutils_$(DEBIAN_INETUTILS_V).debian.tar.xz,debian,inetutils/debian)
	$(call DO_PATCH,inetutils,inetutils,-p1)
	sed -i 's/#include <libinetutils.h>/#include <libinetutils.h>\n#undef true\n#undef false/' $(BUILD_WORK)/inetutils/src/rlogind.c
	mkdir -p $(BUILD_STAGE)/inetutils/{{s,}bin/,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{1,8}}

ifneq ($(wildcard $(BUILD_WORK)/inetutils/.build_complete),)
inetutils:
	@echo "Using previously built inetutils."
else
inetutils: inetutils-setup ncurses readline openpam libidn2
	cd $(BUILD_WORK)/inetutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-ifconfig \
		--disable-syslogd \
		--disable-traceroute \
		--disable-whois \
		--with-pam \
		--with-idn \
		--with-packager="Procursus" \
		--program-prefix=inetutils-
	sed -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnet/Makefile
	sed -i 's/-ltermcap/-lncursesw/g' $(BUILD_WORK)/inetutils/telnetd/Makefile
	$(MAKE) -C $(BUILD_WORK)/inetutils install \
		DESTDIR=$(BUILD_STAGE)/inetutils
	$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/bin
	$(LN_S) ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ping $(BUILD_STAGE)/inetutils/sbin
	-for bin in ftp ftpd inetd ping ping6 talk talkd telnet dnsdomainname hostname logger; do \
		[ -f $(BUILD_WORK)/inetutils/debian/local/man/$$bin.1 ] && $(INSTALL) -m644 $(BUILD_WORK)/inetutils/debian/local/man/$$bin.1 $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/inetutils-$$bin.1; \
		[ -f $(BUILD_WORK)/inetutils/debian/local/man/$$bin.8 ] && $(INSTALL) -m644 $(BUILD_WORK)/inetutils/debian/local/man/$$bin.8 $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/inetutils-$$bin.8; \
	done
	$(call AFTER_BUILD)
endif

inetutils-package: inetutils-stage
	# inetutils.mk Package Structure
	rm -rf $(BUILD_DIST)/inetutils-{ping,telnet,ftp,ftpd,tftp,tftpd,talk,talkd,inetd,telnet,telnetd,tools,rlogin,rlogind,rexec,rexecd,rsh,rcp,uucpd,rshd}
	mkdir -p $(BUILD_DIST)/inetutils-{ping,telnet,ftp,ftpd,tftp,tftpd,talk,talkd,inetd,telnetd,tools,rlogin,rlogind,rexec,rexecd,rcp,uucpd,rshd}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/inetutils-{ping,telnet,ftp,tftp,talk,rlogin,rexec,rcp,rsh,tools}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	mkdir -p $(BUILD_DIST)/inetutils-{telnet,ftp,rsh,tftp,talk,rlogin,rexec,uucp,inet}d/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{libexec,share/man/man8}}
	mkdir -p $(BUILD_DIST)/inetutils-ftpd/$(MEMO_PREFIX)/etc

	# inetutils.mk Prep inetutils-{telnet,ftp,tftp,talk,rlogin,rexec,rcp,rsh}
	-for bin in inetutils-{telnet,ftp,tftp,talk,rlogin,rexec,rcp,rsh}; do \
		cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin} $(BUILD_DIST)/$${bin}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
		cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$${bin}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/$${bin}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 2> /dev/null; \
	done

	# inetutils.mk Prep inetutils-{telnet,ftp,tftp,talk,rlogin,rexec,uucp,inet,rsh}d
	for daemon in inetutils-{telnet,ftp,tftp,talk,rlogin,rexec,uucp,inet,rsh}d; do \
		cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/$${daemon} $(BUILD_DIST)/$${daemon}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec; \
		sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' "$(BUILD_MISC)/inetutils/org.gnu.inetutils.$$(echo "$${daemon}" | cut -d- -f2).plist" > $(BUILD_DIST)/$${daemon}/$(MEMO_PREFIX)/Library/LaunchDaemons/org.gnu.inetutils.$$(echo "$${daemon}" | cut -d- -f2).plist; \
		cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/$${daemon}.8$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/$${daemon}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8 2> /dev/null || true; \
	done
	touch $(BUILD_DIST)/inetutils-ftpd/$(MEMO_PREFIX)/etc/ftp{chroot,users,welcome}

	# inetutils.mk Prep inetutils-ping
	cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/inetutils-ping{,6} $(BUILD_DIST)/inetutils-ping/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/inetutils-ping{,6}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/inetutils-ping/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \

	# inetutils.mk Prep inetutils-tools
	cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/inetutils-{dnsdomainname,hostname,logger} $(BUILD_DIST)/inetutils-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	cp -a $(BUILD_STAGE)/inetutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/inetutils-{dnsdomainname,hostname,logger}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/inetutils-ping/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \

	# inetutils.mk Sign
	$(call SIGN,inetutils-ping,general.xml)
	$(call SIGN,inetutils-telnet,general.xml)
	$(call SIGN,inetutils-telnetd,general.xml)
	$(call SIGN,inetutils-tools,general.xml)
	$(call SIGN,inetutils-ftp,general.xml)
	$(call SIGN,inetutils-ftpd,general.xml)
	$(call SIGN,inetutils-tftp,general.xml)
	$(call SIGN,inetutils-tftpd,general.xml)
	$(call SIGN,inetutils-inetd,general.xml)
	$(call SIGN,inetutils-rexec,general.xml)
	$(call SIGN,inetutils-rexecd,general.xml)
	$(call SIGN,inetutils-rlogin,general.xml)
	$(call SIGN,inetutils-rlogind,general.xml)
	$(call SIGN,inetutils-talk,general.xml)
	$(call SIGN,inetutils-talkd,general.xml)
	$(call SIGN,inetutils-uucpd,general.xml)
	$(call SIGN,inetutils-rsh,general.xml)
	$(call SIGN,inetutils-rshd,general.xml)
	$(call SIGN,inetutils-rcp,general.xml)

	# inetutils.mk Permissions
	$(FAKEROOT) chmod 0755 $(BUILD_DIST)/inetutils-*/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	$(FAKEROOT) chmod 4755 $(BUILD_DIST)/inetutils-*/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/inetutils-{ping{,6},rcp,rlogin,rsh}

	# inetutils.mk Make .debs
	$(call PACK,inetutils-ping,DEB_INETUTILS_V)
	$(call PACK,inetutils-telnet,DEB_INETUTILS_V)
	$(call PACK,inetutils-telnetd,DEB_INETUTILS_V)
	$(call PACK,inetutils-tools,DEB_INETUTILS_V)
	$(call PACK,inetutils-ftp,DEB_INETUTILS_V)
	$(call PACK,inetutils-ftpd,DEB_INETUTILS_V)
	$(call PACK,inetutils-tftp,DEB_INETUTILS_V)
	$(call PACK,inetutils-tftpd,DEB_INETUTILS_V)
	$(call PACK,inetutils-inetd,DEB_INETUTILS_V)
	$(call PACK,inetutils-rexec,DEB_INETUTILS_V)
	$(call PACK,inetutils-rexecd,DEB_INETUTILS_V)
	$(call PACK,inetutils-rlogin,DEB_INETUTILS_V)
	$(call PACK,inetutils-rlogind,DEB_INETUTILS_V)
	$(call PACK,inetutils-talk,DEB_INETUTILS_V)
	$(call PACK,inetutils-talkd,DEB_INETUTILS_V)
	$(call PACK,inetutils-uucpd,DEB_INETUTILS_V)
	$(call PACK,inetutils-rsh,DEB_INETUTILS_V)
	$(call PACK,inetutils-rshd,DEB_INETUTILS_V)
	$(call PACK,inetutils-rcp,DEB_INETUTILS_V)

	# inetutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/inetutils-{ping,telnet,ftp,ftpd,tftp,tftpd,talk,inetd,telnet,telnetd,tools,rlogin,rlogind,rexec,rexecd,rsh,rcp,uucpd,rshd,talkd}

.PHONY: inetutils inetutils-package
