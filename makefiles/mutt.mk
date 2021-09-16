ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mutt
MUTT_VERSION := 2.0.6
DEB_MUTT_V   ?= $(MUTT_VERSION)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
MUTT_CONFIGURE_ARGS := --with-sasl --with-gss
endif

mutt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) ftp://ftp.mutt.org/pub/mutt/mutt-$(MUTT_VERSION).tar.gz
	$(call EXTRACT_TAR,mutt-$(MUTT_VERSION).tar.gz,mutt-$(MUTT_VERSION),mutt)
	$(call DO_PATCH,mutt,mutt,-p1)

ifneq ($(call HAS_COMMAND,lynx),1)
mutt:
	@echo "Install lynx before building"
else ifneq ($(wildcard $(BUILD_WORK)/mutt/.build_complete),)
mutt:
	@echo "Using previously built mutt."
else
mutt: mutt-setup gettext tokyocabinet ncurses gpgme libidn2 gnutls
	cd $(BUILD_WORK)/mutt && autoreconf -fi
	cd $(BUILD_WORK)/mutt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-mailpath=/var/mail \
		--enable-compressed \
		--enable-debug \
		--enable-fcntl \
		--enable-hcache \
		--enable-gpgme \
		--enable-imap \
		--enable-smtp \
		--enable-pop \
		--enable-sidebar \
		--enable-dotlock \
		--disable-fmemopen \
		--with-curses=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-gnutls \
		--with-idn2 \
		--with-mixmaster\
		--without-gdbm \
		--without-bdb \
		--without-qdbm \
		--with-tokyocabinet \
		$(MUTT_CONFIGURE_ARGS) \
		GPGME_CONFIG=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpgme-config \
		GPG_ERROR_CONFIG=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gpg-error-config \
		mutt_cv_c99_snprintf=yes \
		mutt_cv_c99_vsnprintf=yes
	+$(MAKE) -C $(BUILD_WORK)/mutt
	+$(MAKE) -C $(BUILD_WORK)/mutt install \
		DESTDIR=$(BUILD_STAGE)/mutt
	mkdir -p $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mutt/
	cp -a $(BUILD_MISC)/mutt/lib/{mailspell,source-muttrc.d,mailto-mutt,debian-ldap-query} \
		$(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mutt/
	sed -i 's/@MEMO_PREFIX@/$(MEMO_PREFIX)/g' $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mutt/*
	mv $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{mutt_pgpring,pgpewrap} \
		$(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mutt/
	( sed -e '/## More settings/,$$d' $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/Muttrc || exit 1 ; \
	  echo "source $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/mutt/source-muttrc.d|" ) > /tmp/Muttrc
	mv /tmp/Muttrc $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/Muttrc
	mkdir -p $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/Muttrc.d/
	cp $(BUILD_WORK)/mutt/contrib/{gpg,smime}.rc \
		$(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/Muttrc.d/
	cp -a $(BUILD_MISC)/mutt/rc/*.rc \
		$(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/Muttrc.d/
	rm -f $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)/etc/{mime.types{,.dist},Muttrc.dist}
	rm -f $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{flea,muttbug}
	mkdir -p $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mime/packages/
	echo 'application/mbox; mutt -Rf %s; edit=mutt -f %s; needsterminal' > $(BUILD_STAGE)/mutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mime/packages/mutt
	$(call AFTER_BUILD)
endif

mutt-package: mutt-stage
	# mutt.mk Package Structure
	rm -rf $(BUILD_DIST)/mutt
	
	# mutt.mk Prep mutt
	cp -a $(BUILD_STAGE)/mutt $(BUILD_DIST)
	
	# mutt.mk Sign
	$(call SIGN,mutt,general.xml)
	
	# mutt.mk Make .debs
	$(call PACK,mutt,DEB_MUTT_V)
	
	# mutt.mk Build cleanup
	rm -rf $(BUILD_DIST)/mutt

.PHONY: mutt mutt-package
