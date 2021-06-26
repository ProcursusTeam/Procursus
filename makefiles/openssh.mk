ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssh
else # ($(SSH_STRAP),1)
SUBPROJECTS     += openssh
endif # ($(SSH_STRAP),1)
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS     += openssh
endif
OPENSSH_VERSION := 8.6p1
DEB_OPENSSH_V   ?= $(OPENSSH_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
OPENSSH_CONFIGURE_ARGS += ac_cv_func_strtonum=no
endif

openssh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$(OPENSSH_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,openssh-$(OPENSSH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssh-$(OPENSSH_VERSION).tar.gz,openssh-$(OPENSSH_VERSION),openssh)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,openssh,openssh,-p1)
endif
	$(SED) -i 's/#UsePAM no/UsePAM yes/' $(BUILD_WORK)/openssh/sshd_config

ifneq ($(wildcard $(BUILD_WORK)/openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
openssh: openssh-setup openssl libxcrypt openpam libmd
else # (,$(findstring darwin,$(MEMO_TARGET)))
OPENSSH_CONFIGURE_ARGS += --with-keychain=apple
openssh: openssh-setup openssl libmd
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	if ! [ -f $(BUILD_WORK)/openssh/configure ]; then \
		cd $(BUILD_WORK)/openssh && autoreconf; \
	fi
	$(SED) -i '/HAVE_ENDIAN_H/d' $(BUILD_WORK)/openssh/config.h.in
	cd $(BUILD_WORK)/openssh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--sysconfdir=$(MEMO_PREFIX)/etc/ssh \
		--with-xauth=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xauth \
		--with-ssl-engine \
		--with-pam \
		check_for_libcrypt_before=1 \
		$(OPENSSH_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/openssh \
		SSHDLIBS="-lcrypt -lsandbox -lpam -ldl"
	+$(MAKE) -C $(BUILD_WORK)/openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	mkdir -p $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library/LaunchDaemons
	mkdir -p $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d
	cp $(BUILD_MISC)/openssh/sshd $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d
	cp $(BUILD_MISC)/openssh/com.openssh.sshd.plist $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp $(BUILD_MISC)/openssh/sshd-keygen-wrapper $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp $(BUILD_WORK)/openssh/contrib/ssh-copy-id $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	chmod 0755 $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ssh-copy-id
	touch $(BUILD_WORK)/openssh/.build_complete
endif

openssh-package: openssh-stage
	# openssh.mk Package Structure
	rm -rf $(BUILD_DIST)/openssh{,-sftp-server,-server,-client}
	mkdir -p $(BUILD_DIST)/openssh \
		$(BUILD_DIST)/openssh-client/{$(MEMO_PREFIX)/var/empty,$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{libexec,share/man/{man1,man5,man8}}} \
		$(BUILD_DIST)/openssh-server/{$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{libexec,share/man/{man5,man8}}} \
		$(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,/share/man/man8}

	# openssh.mk Prep openssh-client
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/ssh/ssh_config $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)/etc/ssh
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/{ssh-keysign,ssh-pkcs11-helper,ssh-sk-helper} $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/ssh_config.5 $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{ssh-keysign.8,ssh-pkcs11-helper.8,ssh-sk-helper.8} $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# openssh.mk Prep openssh-server
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/ssh/{moduli,sshd_config} $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)/etc/ssh
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)/etc
endif
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sshd-keygen-wrapper $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/{moduli.5,sshd_config.5} $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/sshd.8 $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)

	# openssh.mk Prep openssh-sftp-server
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sftp-server $(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/sftp-server.8 $(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# openssh.mk Sign
	$(call SIGN,openssh-client,general.xml)
	$(call SIGN,openssh-server,pam.xml)
	$(call SIGN,openssh-sftp-server,general.xml)

	# openssh.mk Make .debs
	$(call PACK,openssh,DEB_OPENSSH_V)
	$(call PACK,openssh-client,DEB_OPENSSH_V)
	$(call PACK,openssh-server,DEB_OPENSSH_V)
	$(call PACK,openssh-sftp-server,DEB_OPENSSH_V)

	# openssh.mk Build cleanup
	rm -rf $(BUILD_DIST)/openssh{,-sftp-server,-server,-client}

.PHONY: openssh openssh-package
