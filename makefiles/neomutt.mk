ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += neomutt
NEOMUTT_VERSION := 20210205
DEB_NEOMUTT_V   ?= $(NEOMUTT_VERSION)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
NEOMUTT_CONFIGURE_ARGS := --sasl --gss
endif

neomutt-setup: setup
	$(call GITHUB_ARCHIVE,neomutt,neomutt,$(NEOMUTT_VERSION),$(NEOMUTT_VERSION))
	$(call EXTRACT_TAR,neomutt-$(NEOMUTT_VERSION).tar.gz,neomutt-$(NEOMUTT_VERSION),neomutt)
	$(call DO_PATCH,neomutt,neomutt,-p1)

ifneq ($(wildcard $(BUILD_WORK)/neomutt/.build_complete),)
neomutt:
	@echo "Using previously built neomutt."
else
neomutt: neomutt-setup gettext zstd lz4 tokyocabinet ncurses gpgme libidn2 gnutls
	cd $(BUILD_WORK)/neomutt && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--with-sysroot=$(BUILD_BASE) \
		--with-mailpath=/var/mail \
		--tokyocabinet \
		--gpgme \
		--fmemopen \
		--with-ui=ncurses \
		--with-ncurses=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--gnutls \
		--idn2 \
		--ssl \
		--gpgme \
		--sqlite \
		--autocrypt \
		--disable-notmuch \
		--disable-idn \
		--with-mixmaster\
		--disable-gdbm \
		--disable-bdb \
		--disable-qdbm \
		--zstd \
		--lz4 \
		$(NEOMUTT_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/neomutt
	+$(MAKE) -C $(BUILD_WORK)/neomutt install \
		DESTDIR=$(BUILD_STAGE)/neomutt
	mkdir -p $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)/etc/neomuttrc.d/
	cp $(BUILD_WORK)/neomutt/contrib/samples/{gpg,smime}.rc \
		$(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)/etc/neomuttrc.d/
	cp -a $(BUILD_MISC)/neomutt/lib/{mailspell,source-neomuttrc.d,mailto-neomutt,debian-ldap-query} \
		$(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neomutt/
	sed -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neomutt/*
	cp -a $(BUILD_MISC)/neomutt/rc/*.rc \
		$(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)/etc/neomuttrc.d/
	chmod +x $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neomutt/*
	( sed -e '/## More settings/,$$d' $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)/etc/neomuttrc || exit 1 ; \
	  echo "source $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/neomutt/source-neomuttrc.d|" ) > /tmp/neomuttrc
	mv /tmp/neomuttrc $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)/etc/neomuttrc
	mkdir -p $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mime/packages/
	echo 'message/rfc822; neomutt -Rf %s; edit=neomutt -f %s; needsterminal' > $(BUILD_STAGE)/neomutt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/mime/packages/neomutt
	$(call AFTER_BUILD)
endif

neomutt-package: neomutt-stage
	# neomutt.mk Package Structure
	rm -rf $(BUILD_DIST)/neomutt
	
	# neomutt.mk Prep neomutt
	cp -a $(BUILD_STAGE)/neomutt $(BUILD_DIST)
	
	# neomutt.mk Sign
	$(call SIGN,neomutt,general.xml)
	
	# neomutt.mk Make .debs
	$(call PACK,neomutt,DEB_NEOMUTT_V)
	
	# neomutt.mk Build cleanup
	rm -rf $(BUILD_DIST)/neomutt

.PHONY: neomutt neomutt-package
