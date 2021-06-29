ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gnupg
GNUPG_VERSION := 2.3.1
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
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(foreach x, libgpg-error libgcrypt libassuan ksba npth, --with-$x-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)) \
		--with-bzip2
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
	mkdir -p $(BUILD_DIST)/dirmngr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{gnupg,man/man{1,8}}} \
		$(BUILD_DIST)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/gnupg-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,8}} \
		$(BUILD_DIST)/gpg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/gpg-agent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec,share/man/man1} \
		$(BUILD_DIST)/gpg-wks-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,share/man/man1} \
		$(BUILD_DIST)/gpg-wks-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/gpgconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{gnupg,man/man1}} \
		$(BUILD_DIST)/gpgsm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/gpgv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/scdaemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,share/man/man1}

	# gnupg.mk Prep dirmngr
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dirmngr* $(BUILD_DIST)/dirmngr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gnupg/sks-keyservers.netCA.pem $(BUILD_DIST)/dirmngr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gnupg
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/dirmngr* $(BUILD_DIST)/dirmngr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/dirmngr* $(BUILD_DIST)/dirmngr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# gnupg.mk Prep gnupg
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man7 $(BUILD_DIST)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gnupg.mk Prep gnupg-utils
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{gpgparsemail,gpgsplit,gpgtar,kbxutil,watchgnupg} $(BUILD_DIST)/gnupg-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{gpgparsemail,gpgtar,watchgnupg}.1 $(BUILD_DIST)/gnupg-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/gnupg-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{addgnupghome,applygnupgdefaults}.8 $(BUILD_DIST)/gnupg-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# gnupg.mk Prep gpg
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpg $(BUILD_DIST)/gpg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpg.1 $(BUILD_DIST)/gpg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gnupg.mk Prep gpg-agent
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpg-agent $(BUILD_DIST)/gpg-agent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpg-agent.1 $(BUILD_DIST)/gpg-agent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/{gpg-check-pattern,gpg-preset-passphrase,gpg-protect-tool} $(BUILD_DIST)/gpg-agent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

	# gnupg.mk Prep gpg-wks-client
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gpg-wks-client $(BUILD_DIST)/gpg-wks-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpg-wks-client.1 $(BUILD_DIST)/gpg-wks-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gnupg.mk Prep gpg-wks-server
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpg-wks-server $(BUILD_DIST)/gpg-wks-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpg-wks-server.1 $(BUILD_DIST)/gpg-wks-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gnupg.mk Prep gpgconf
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{gpgconf,gpg-connect-agent} $(BUILD_DIST)/gpgconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{gpgconf,gpg-connect-agent}.1 $(BUILD_DIST)/gpgconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gnupg/distsigkey.gpg $(BUILD_DIST)/gpgconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gnupg

	# gnupg.mk Prep gpgsm
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpgsm $(BUILD_DIST)/gpgsm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpgsm.1 $(BUILD_DIST)/gpgsm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gnupg.mk Prep gpgv
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpgv $(BUILD_DIST)/gpgv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gpgv.1 $(BUILD_DIST)/gpgv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gnupg.mk Prep scdaemon
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/scdaemon $(BUILD_DIST)/scdaemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/gnupg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/scdaemon.1 $(BUILD_DIST)/scdaemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

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
