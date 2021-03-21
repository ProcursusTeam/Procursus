ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += sudo
SUDO_CONFIGURE_ARGS += --without-pam \
ac_cv_search_crypt="-lcrypt"
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += sudo
SUDO_CONFIGURE_ARGS += --with-pam
endif # ($(MEMO_TARGET),darwin-\*)
SUDO_VERSION  := 1.9.6p1
DEB_SUDO_V    ?= $(SUDO_VERSION)

sudo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.sudo.ws/dist/sudo-$(SUDO_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,sudo-$(SUDO_VERSION).tar.gz)
	$(call EXTRACT_TAR,sudo-$(SUDO_VERSION).tar.gz,sudo-$(SUDO_VERSION),sudo)

ifneq ($(wildcard $(BUILD_WORK)/sudo/.build_complete),)
sudo:
	@echo "Using previously built sudo."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
sudo: sudo-setup gettext libxcrypt
	$(SED) -i 's/errno == ENOEXEC)/(errno == ENOEXEC || errno == EPERM))/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i 's/+ 2/+ 4/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i 's/nargv\[1\] = (char \*)path;/nargv\[1\] = "-c";/g' $(BUILD_WORK)/sudo/src/exec_common.c
	$(SED) -i '/nargv\[1\]/a \	\	nargv[2] = "exec \\"$$0\\" \\"$$@\\"";\
\	\	nargv[3] = (char *)path;' $(BUILD_WORK)/sudo/src/exec_common.c
else
sudo: sudo-setup gettext
endif
	cd $(BUILD_WORK)/sudo && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--localstatedir=$(MEMO_PREFIX)/var \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--enable-static-sudoers \
		--with-all-insults \
		--with-env-editor \
		--with-editor=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/editor \
		--with-timeout=15 \
		--with-password-timeout=0 \
		--with-passprompt="[sudo] password for %p: " \
		sudo_cv___func__=yes \
		$(SUDO_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/sudo
	+$(MAKE) -C $(BUILD_WORK)/sudo install \
		DESTDIR=$(BUILD_STAGE)/sudo \
		INSTALL_OWNER=''
	cp -a $(BUILD_MISC)/procursus.sudoers $(BUILD_STAGE)/sudo/$(MEMO_PREFIX)/etc/sudoers.d/procursus
	touch $(BUILD_WORK)/sudo/.build_complete
endif 

sudo-package: sudo-stage
	# sudo.mk Package Structure
	rm -rf $(BUILD_DIST)/sudo
	
	# sudo.mk Prep sudo
	cp -a $(BUILD_STAGE)/sudo $(BUILD_DIST)
	
	# sudo.mk Sign
	$(call SIGN,sudo,general.xml)

	# sudo.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/sudo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sudo
	$(FAKEROOT) chmod -R 0440 $(BUILD_DIST)/sudo/$(MEMO_PREFIX)/etc/sudoers.d
	
	# sudo.mk Make .debs
	$(call PACK,sudo,DEB_SUDO_V)
	
	# sudo.mk Build cleanup
	rm -rf $(BUILD_DIST)/sudo

.PHONY: sudo sudo-package
