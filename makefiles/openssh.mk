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
OPENSSH_VERSION := 9.7p1
DEB_OPENSSH_V   ?= $(OPENSSH_VERSION)-1

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
OPENSSH_CONFIGURE_ARGS += ac_cv_func_strtonum=no
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
OPENSSH_EMBEDDED_SSHD_LIBS = -lcrypt
endif

openssh-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$(OPENSSH_VERSION).tar.gz{$(comma).asc})
	$(call PGP_VERIFY,openssh-$(OPENSSH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssh-$(OPENSSH_VERSION).tar.gz,openssh-$(OPENSSH_VERSION),openssh)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,openssh,openssh,-p1)
endif
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	sed -i 's/#UsePAM no/UsePAM yes/' $(BUILD_WORK)/openssh/sshd_config
endif #(,$(findstring ramdisk,$(MEMO_TARGET)))

ifneq ($(wildcard $(BUILD_WORK)/openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
openssh: openssh-setup openssl libxcrypt openpam libmd
else #(,$(findstring ramdisk,$(MEMO_TARGET)))
openssh: openssh-setup openssl libmd
endif #(,$(findstring ramdisk,$(MEMO_TARGET)))
else # (,$(findstring darwin,$(MEMO_TARGET)))
OPENSSH_CONFIGURE_ARGS += --with-keychain=apple
openssh: openssh-setup openssl libmd
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	if ! [ -f $(BUILD_WORK)/openssh/configure ]; then \
		cd $(BUILD_WORK)/openssh && autoreconf; \
	fi
	sed -i '/HAVE_ENDIAN_H/d' $(BUILD_WORK)/openssh/config.h.in
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/openssh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--sysconfdir=$(MEMO_PREFIX)/etc/ssh \
		--with-xauth=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xauth \
		--with-ssl-engine \
		--with-pam \
		check_for_libcrypt_before=1 \
		$(OPENSSH_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/openssh \
		SSHDLIBS="$(OPENSSH_EMBEDDED_SSHD_LIBS) -lsandbox -lpam -ldl" \
		CONFIG_FILE="$(MEMO_PREFIX)/etc/openssh.conf" \
		piddir="$(MEMO_PREFIX)/var/run" \
		PRIVSEP_PATH="$(MEMO_PREFIX)/var/empty"
	+$(MAKE) -C $(BUILD_WORK)/openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh" \
		CONFIG_FILE="$(MEMO_PREFIX)/etc/openssh.conf" \
		piddir="$(MEMO_PREFIX)/var/run" \
		PRIVSEP_PATH="$(MEMO_PREFIX)/var/empty"
	mkdir -p $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d
	cp $(BUILD_MISC)/openssh/sshd $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d
else # (,$(findstring ramdisk,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/openssh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--sysconfdir=$(MEMO_PREFIX)/etc/ssh \
		--with-ssl-engine \
		check_for_libcrypt_before=1 \
		$(OPENSSH_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/openssh \
		SSHDLIBS="" \
		CONFIG_FILE="$(MEMO_PREFIX)/etc/openssh.conf" \
		piddir="$(MEMO_PREFIX)/var/run" \
		PRIVSEP_PATH="$(MEMO_PREFIX)/var/empty"
	+$(MAKE) -C $(BUILD_WORK)/openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh" \
		CONFIG_FILE="$(MEMO_PREFIX)/etc/openssh.conf" \
		piddir="$(MEMO_PREFIX)/var/run" \
		PRIVSEP_PATH="$(MEMO_PREFIX)/var/empty"
endif #(,$(findstring ramdisk,$(MEMO_TARGET)))
	mkdir -p $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp $(BUILD_MISC)/openssh/com.openssh.sshd.plist $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp $(BUILD_MISC)/openssh/sshd-keygen-wrapper $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	sed -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sshd-keygen-wrapper $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library/LaunchDaemons/com.openssh.sshd.plist
	cp $(BUILD_WORK)/openssh/contrib/ssh-copy-id $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/openssh/contrib/ssh-copy-id.1 $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	chmod 0755 $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ssh-copy-id
	$(call AFTER_BUILD)
endif

openssh-package: openssh-stage
	# openssh.mk Package Structure
	rm -rf $(BUILD_DIST)/openssh{,-sftp-server,-server,-client}
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/openssh \
		$(BUILD_DIST)/openssh-client/{$(MEMO_PREFIX)/var/empty,$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{libexec,share/man/{man1,man5,man8}}} \
		$(BUILD_DIST)/openssh-server/{$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{libexec,share/man/{man5,man8}}} \
		$(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{libexec,/share/man/man8}
else
	mkdir -p $(BUILD_DIST)/openssh \
		$(BUILD_DIST)/openssh-client/{$(MEMO_PREFIX)/var/empty,$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/libexec} \
		$(BUILD_DIST)/openssh-server/{$(MEMO_PREFIX)/etc/ssh,$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/libexec} \
		$(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
endif

	# openssh.mk Prep openssh-client
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/ssh/ssh_config $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)/etc/ssh
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/{ssh-keysign,ssh-pkcs11-helper,ssh-sk-helper} $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/ssh_config.5$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{ssh-keysign.8,ssh-pkcs11-helper.8,ssh-sk-helper.8}$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/openssh-client/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
endif

	# openssh.mk Prep openssh-server
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/ssh/{moduli,sshd_config} $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)/etc/ssh
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/etc/pam.d $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)/etc
endif
endif
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sshd-keygen-wrapper $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/{moduli.5,sshd_config.5}$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/sshd.8$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
endif
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)/Library $(BUILD_DIST)/openssh-server/$(MEMO_PREFIX)

	# openssh.mk Prep openssh-sftp-server
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sftp-server $(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/openssh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/sftp-server.8$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/openssh-sftp-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
endif
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
