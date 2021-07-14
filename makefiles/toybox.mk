
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += toybox
TOYBOX_VERSION := 0.8.5
DEB_TOYBOX_V   ?= $(TOYBOX_VERSION)

toybox-setup: setup
	$(call GITHUB_ARCHIVE,landley,toybox,$(TOYBOX_VERSION),$(TOYBOX_VERSION))
	$(call EXTRACT_TAR,toybox-$(TOYBOX_VERSION).tar.gz,toybox-$(TOYBOX_VERSION),toybox)
	$(SED) -i s/utmp.h/utmpx.h/g $(BUILD_WORK)/toybox/toys/pending/last.c
	$(SED) -i 's|struct utmp|struct utmpx|g' $(BUILD_WORK)/toybox/toys/pending/last.c
	$(SED) -i 's|syscall(__NR_|syscall(|g' $(BUILD_WORK)/toybox/toys/other/ionice.c
	$(SED) -i 's|UT_LINESIZE|13838852|g' $(BUILD_WORK)/toybox/toys/pending/last.c
	$(SED) -i '1 i\#define LOGIN_NAME_MAX 256' $(BUILD_WORK)/toybox/toys/pending/useradd.c
	$(CP) -a $(BUILD_MISC)/toybox/config $(BUILD_WORK)/toybox/.config

ifneq ($(wildcard $(BUILD_WORK)/toybox/.build_complete),)
toybox:
	@echo "Using previously built toybox."
else
toybox: toybox-setup openssl libxcrypt
	$(MAKE) -C $(BUILD_WORK)/toybox menuconfig
	$(MAKE) -C $(BUILD_WORK)/toybox
	+$(MAKE) -C $(BUILD_WORK)/toybox install \
		PREFIX=$(BUILD_STAGE)/toybox
	touch $(BUILD_WORK)/toybox/.build_complete
endif

toybox-package: toybox-stage
	# toybox.mk Package Structure
	rm -rf $(BUILD_DIST)/toybox
	mkdir -p $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# toybox.mk Prep toybox
	$(INSTALL) -m755 $(BUILD_STAGE)/toybox/bin/toybox $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# toybox.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/toybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/toybox

	# toybox.mk Sign
	$(call SIGN,toybox,dd.xml)
	
	# toybox.mk Make .debs
	$(call PACK,toybox,DEB_TOYBOX_V)
	
	# toybox.mk Build cleanup
	rm -rf $(BUILD_DIST)/toybox

.PHONY: toybox toybox-package
