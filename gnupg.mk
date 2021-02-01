ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gnupg
GNUPG_VERSION := 2.2.27
DEB_GNUPG_V   ?= $(GNUPG_VERSION)-1

gnupg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(GNUPG_VERSION).tar.bz2
	$(call EXTRACT_TAR,gnupg-$(GNUPG_VERSION).tar.bz2,gnupg-$(GNUPG_VERSION),gnupg)

ifneq ($(wildcard $(BUILD_WORK)/gnupg/.build_complete),)
gnupg:
	@echo "Using previously built gnupg."
else
gnupg: gnupg-setup readline libgpg-error libgcrypt libassuan libksba npth gettext gnutls libusb
	cd $(BUILD_WORK)/gnupg && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		$(foreach x, libgpg-error libgcrypt libassuan ksba npth, --with-$x-prefix=$(BUILD_BASE)/usr) \
		--with-bzip2 \
		--sysconfdir=/etc
	+$(MAKE) -C $(BUILD_WORK)/gnupg
	+$(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_STAGE)/gnupg
	+$(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gnupg/.build_complete
endif

gnupg-package: gnupg-stage
	# gnupg.mk Package Structure
	rm -rf $(BUILD_DIST)/dirmngr $(BUILD_DIST)/gnupg{,-utils} $(BUILD_DIST)/gpg{,-agent,-wks-{client,server},conf,sm,v} $(BUILD_DIST)/scdaemon
	mkdir -p $(BUILD_DIST)/dirmngr/usr/{bin,share/{gnupg,man/man{1,8}}} \
		$(BUILD_DIST)/gnupg/usr/share/man \
		$(BUILD_DIST)/gnupg-utils/usr/{bin,share/man/man{1,8}} \
		$(BUILD_DIST)/gpg/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/gpg-agent/usr/{bin,libexec,share/man/man1} \
		$(BUILD_DIST)/gpg-wks-client/usr/{libexec,share/man/man1} \
		$(BUILD_DIST)/gpg-wks-server/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/gpgconf/usr/{bin,share/{gnupg,man/man1}} \
		$(BUILD_DIST)/gpgsm/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/gpgv/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/scdaemon/usr/{libexec,share/man/man1}
	
	# gnupg.mk Prep dirmngr
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/dirmngr* $(BUILD_DIST)/dirmngr/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/gnupg/sks-keyservers.netCA.pem $(BUILD_DIST)/dirmngr/usr/share/gnupg
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/dirmngr* $(BUILD_DIST)/dirmngr/usr/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man8/dirmngr* $(BUILD_DIST)/dirmngr/usr/share/man/man8

	# gnupg.mk Prep gnupg
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man7 $(BUILD_DIST)/gnupg/usr/share/man
	cp -a $(BUILD_STAGE)/gnupg/usr/share/locale $(BUILD_DIST)/gnupg/usr/share

	# gnupg.mk Prep gnupg-utils
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/{gpgparsemail,gpgsplit,gpgtar,kbxutil,watchgnupg} $(BUILD_DIST)/gnupg-utils/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/{gpgparsemail,gpgtar,watchgnupg}.1 $(BUILD_DIST)/gnupg-utils/usr/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/usr/sbin $(BUILD_DIST)/gnupg-utils/usr
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man8/{addgnupghome,applygnupgdefaults}.8 $(BUILD_DIST)/gnupg-utils/usr/share/man/man8

	# gnupg.mk Prep gpg
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/gpg $(BUILD_DIST)/gpg/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpg.1 $(BUILD_DIST)/gpg/usr/share/man/man1

	# gnupg.mk Prep gpg-agent
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/gpg-agent $(BUILD_DIST)/gpg-agent/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpg-agent.1 $(BUILD_DIST)/gpg-agent/usr/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/usr/libexec/{gpg-check-pattern,gpg-preset-passphrase,gpg-protect-tool} $(BUILD_DIST)/gpg-agent/usr/libexec

	# gnupg.mk Prep gpg-wks-client
	cp -a $(BUILD_STAGE)/gnupg/usr/libexec/gpg-wks-client $(BUILD_DIST)/gpg-wks-client/usr/libexec
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpg-wks-client.1 $(BUILD_DIST)/gpg-wks-client/usr/share/man/man1

	# gnupg.mk Prep gpg-wks-server
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/gpg-wks-server $(BUILD_DIST)/gpg-wks-server/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpg-wks-server.1 $(BUILD_DIST)/gpg-wks-server/usr/share/man/man1

	# gnupg.mk Prep gpgconf
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/{gpgconf,gpg-connect-agent} $(BUILD_DIST)/gpgconf/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/{gpgconf,gpg-connect-agent}.1 $(BUILD_DIST)/gpgconf/usr/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/usr/share/gnupg/distsigkey.gpg $(BUILD_DIST)/gpgconf/usr/share/gnupg

	# gnupg.mk Prep gpgsm
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/gpgsm $(BUILD_DIST)/gpgsm/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpgsm.1 $(BUILD_DIST)/gpgsm/usr/share/man/man1

	# gnupg.mk Prep gpgv
	cp -a $(BUILD_STAGE)/gnupg/usr/bin/gpgv $(BUILD_DIST)/gpgv/usr/bin
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/gpgv.1 $(BUILD_DIST)/gpgv/usr/share/man/man1

	# gnupg.mk Prep scdaemon
	cp -a $(BUILD_STAGE)/gnupg/usr/libexec/scdaemon $(BUILD_DIST)/scdaemon/usr/libexec
	cp -a $(BUILD_STAGE)/gnupg/usr/share/man/man1/scdaemon.1 $(BUILD_DIST)/scdaemon/usr/share/man/man1

	# gnupg.mk Sign
	$(call SIGN,dirmngr,general.xml)
	$(call SIGN,gnupg-utils,general.xml)
	$(call SIGN,gpg,general.xml)
	$(call SIGN,gpg-agent,general.xml)
	$(call SIGN,gpg-wks-client,general.xml)
	$(call SIGN,gpg-wks-server,general.xml)
	$(call SIGN,gpgconf,general.xml)
	$(call SIGN,gpgsm,general.xml)
	$(call SIGN,gpgv,general.xml)
	$(call SIGN,scdaemon,general.xml)
	
	# gnupg.mk Make .debs
	$(call PACK,gnupg,DEB_GNUPG_V)
	$(call PACK,dirmngr,DEB_GNUPG_V)
	$(call PACK,gnupg-utils,DEB_GNUPG_V)
	$(call PACK,gpg,DEB_GNUPG_V)
	$(call PACK,gpg-agent,DEB_GNUPG_V)
	$(call PACK,gpg-wks-client,DEB_GNUPG_V)
	$(call PACK,gpg-wks-server,DEB_GNUPG_V)
	$(call PACK,gpgconf,DEB_GNUPG_V)
	$(call PACK,gpgsm,DEB_GNUPG_V)
	$(call PACK,gpgv,DEB_GNUPG_V)
	$(call PACK,scdaemon,DEB_GNUPG_V)
	
	# gnupg.mk Build cleanup
	rm -rf $(BUILD_DIST)/dirmngr $(BUILD_DIST)/gnupg{,-utils} $(BUILD_DIST)/gpg{,-agent,-wks-{client,server},conf,sm,v} $(BUILD_DIST)/scdaemon

.PHONY: gnupg gnupg-package
