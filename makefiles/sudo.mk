ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += sudo
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += sudo
endif # ($(MEMO_TARGET),darwin-\*)
SUDO_VERSION  := 1.9.15p5
DEB_SUDO_V    ?= $(SUDO_VERSION)

sudo-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.sudo.ws/dist/sudo-$(SUDO_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,sudo-$(SUDO_VERSION).tar.gz)
	$(call EXTRACT_TAR,sudo-$(SUDO_VERSION).tar.gz,sudo-$(SUDO_VERSION),sudo)
	$(call DO_PATCH,sudo,sudo,-p1)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifneq (1,$(MEMO_NO_IOSEXEC))
	sed -i -E 's/(testsudoers|sudo)_((get|set|end)(user|gr|pw)(shell|ent|nam|uid|gid))_?r?\(/\1_ie_\2\(/g' $(BUILD_WORK)/sudo/{plugins/sudoers,lib/util}/*.*
endif
endif

ifneq ($(wildcard $(BUILD_WORK)/sudo/.build_complete),)
sudo:
	@echo "Using previously built sudo."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
sudo: sudo-setup gettext
else
sudo: sudo-setup gettext openpam libiosexec
endif
	cd $(BUILD_WORK)/sudo && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pam \
		--enable-static-sudoers \
		--with-all-insults \
		--with-env-editor \
		--with-editor=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/editor \
		--with-timeout=15 \
		--with-password-timeout=0 \
		--with-passprompt="[sudo] password for %p: " \
		--with-vardir=$(MEMO_PREFIX)/var/db/sudo \
		--with-rundir=$(MEMO_PREFIX)/var/run/sudo \
		sudo_cv___func__=yes \
		ac_cv_have_working_snprintf=yes \
		ac_cv_have_working_vsnprintf=yes \
		ac_cv_header_libutil_h=no
	sed -i 's/-Wc,-static-libgcc/ /g' $(BUILD_WORK)/sudo/{src,,plugins/*,logsrvd,lib/util}/Makefile
	+$(MAKE) -C $(BUILD_WORK)/sudo
	+$(MAKE) -C $(BUILD_WORK)/sudo install \
		DESTDIR=$(BUILD_STAGE)/sudo \
		INSTALL_OWNER=''
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_STAGE)/sudo/$(MEMO_PREFIX)/etc/pam.d
	cp -a $(BUILD_MISC)/pam/sudo $(BUILD_STAGE)/sudo/$(MEMO_PREFIX)/etc/pam.d
endif
	cp -a $(BUILD_MISC)/procursus.sudoers $(BUILD_STAGE)/sudo/$(MEMO_PREFIX)/etc/sudoers.d/procursus
	$(I_N_T) -add_rpath $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/sudo $(BUILD_STAGE)/sudo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sudo
	$(call AFTER_BUILD)
endif

sudo-package: sudo-stage
	# sudo.mk Package Structure
	rm -rf $(BUILD_DIST)/sudo

	# sudo.mk Prep sudo
	cp -a $(BUILD_STAGE)/sudo $(BUILD_DIST)

	# sudo.mk Sign
	$(call SIGN,sudo,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -M -S$(BUILD_MISC)/entitlements/pam.xml $(BUILD_DIST)/sudo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sudo
	find $(BUILD_DIST)/sudo -name '.ldid*' -type f -delete
endif

	# sudo.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/sudo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sudo

	# sudo.mk Make .debs
	$(call PACK,sudo,DEB_SUDO_V)

	# sudo.mk Build cleanup
	rm -rf $(BUILD_DIST)/sudo

.PHONY: sudo sudo-package
