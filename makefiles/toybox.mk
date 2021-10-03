ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += toybox
TOYBOX_VERSION := 0.8.5
DEB_TOYBOX_V   ?= $(TOYBOX_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
TOYBOX_DEPS := libxcrypt
endif

toybox-setup: setup
	$(call GITHUB_ARCHIVE,landley,toybox,$(TOYBOX_VERSION),$(TOYBOX_VERSION))
	$(call EXTRACT_TAR,toybox-$(TOYBOX_VERSION).tar.gz,toybox-$(TOYBOX_VERSION),toybox)
	sed -i s/utmp.h/utmpx.h/g $(BUILD_WORK)/toybox/toys/pending/last.c
	sed -i 's|struct utmp|struct utmpx|g' $(BUILD_WORK)/toybox/toys/pending/last.c
	sed -i 's|syscall(__NR_|syscall(|g' $(BUILD_WORK)/toybox/toys/other/ionice.c
	sed -i 's|UT_LINESIZE|_UTX_LINESIZE|g' $(BUILD_WORK)/toybox/toys/pending/last.c
	sed -i '1 i\#define LOGIN_NAME_MAX _SC_LOGIN_NAME_MAX' $(BUILD_WORK)/toybox/toys/pending/{user,group}add.c
	sed -i -e 's/-Wl,--gc-sections//g' -e 's/-Wl,--as-needed//g' $(BUILD_WORK)/toybox/configure
ifneq (,$(findstring rootless,$(MEMO_TARGET)))
	sed -i -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/var|$(MEMO_PREFIX)/var|g' $(BUILD_WORK)/toybox/toys/pending/{useradd,userdel,crontab,crond,last,telnetd,init}.c
endif
	sed -i -e 's|/usr|$(MEMO_PREIFX)$(MEMO_SUB_PREFIX)|g' $(BUILD_WORK)/toybox/toys/posix/file.c
	cp -a $(BUILD_MISC)/toybox/config $(BUILD_WORK)/toybox/.config

ifneq ($(wildcard $(BUILD_WORK)/toybox/.build_complete),)
toybox:
	@echo "Using previously built toybox."
else
toybox: toybox-setup openssl $(TOYBOX_DEPS)
	$(MAKE) -C $(BUILD_WORK)/toybox
	+$(MAKE) -C $(BUILD_WORK)/toybox install \
		PREFIX=$(BUILD_STAGE)/toybox
	chmod 755 $(BUILD_STAGE)/toybox/$(MEMO_PREFIX)/bin/toybox
	$(call AFTER_BUILD)
endif

toybox-package: toybox-stage
	# toybox.mk Package Structure
	rm -rf $(BUILD_DIST)/toybox
	mkdir -p $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# toybox.mk Prep toybox
	$(INSTALL) -m755 $(BUILD_STAGE)/toybox/bin/toybox $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# toybox.mk Sign
	$(call SIGN,toybox,dd.xml)
	
	# toybox.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/toybox
	
	# toybox.mk Make .debs
	$(call PACK,toybox,DEB_TOYBOX_V)
	
	# toybox.mk Build cleanup
	rm -rf $(BUILD_DIST)/toybox

.PHONY: toybox toybox-package
