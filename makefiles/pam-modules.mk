ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS       += pam-modules
PAM-MODULES_VERSION := 1000.0
DEB_PAM-MODULES_V   ?= $(PAM-MODULES_VERSION)

###
# TODO: Have a look at the sacl and launchd and utmpw modules.
###

pam-modules-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,pam_modules,$(PAM-MODULES_VERSION),$(PAM-MODULES_VERSION))
	$(call EXTRACT_TAR,pam_modules-$(PAM-MODULES_VERSION).tar.gz,pam_modules-$(PAM-MODULES_VERSION),pam-modules)
	mkdir -p $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pam,share/man/man8}
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/pam-modules, \
		https://github.com/apple-oss-distributions/Libinfo/raw/Libinfo-542.40.3/membership.subproj/membershipPriv.h)

ifneq ($(wildcard $(BUILD_WORK)/pam-modules/.build_complete),)
pam-modules:
	@echo "Using previously built pam-modules."
else
pam-modules: pam-modules-setup openpam libxcrypt
	set -e; \
	cd $(BUILD_WORK)/pam-modules; \
	$(CC) $(CFLAGS) -I$(BUILD_WORK)/pam-modules -I$(BUILD_WORK)/pam-modules/libc/gen -I$(BUILD_WORK)/pam-modules/libutil -bundle -o pam_unix.so pam_unix/*.c libutil/*.c $(BUILD_WORK)/pam-modules/libc/gen/pw_scan.c $(LDFLAGS) -lpam -lcrypt || true; \
	$(CC) $(CFLAGS) -I$(BUILD_WORK)/pam-modules -I$(BUILD_WORK)/pam-modules/libc/gen -I$(BUILD_WORK)/pam-modules/libutil -bundle -o pam_nologin.so pam_nologin/*.c libutil/*.c $(BUILD_WORK)/pam-modules/libc/gen/pw_scan.c $(LDFLAGS) -lpam || true; \
	cp -a pam_unix.so pam_nologin.so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam; \
	install -m644 pam_unix/pam_unix.8 pam_nologin/pam_nologin.8 $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/; \
	for module in deny group launchd permit rootok sacl self uwtmp; do \
		echo $${module}; \
		$(CC) $(CFLAGS) -I$(BUILD_WORK)/pam-modules -bundle -o pam_$${module}.so pam_$${module}/*.c $(LDFLAGS) -lpam || true; \
		cp -a pam_$${module}.so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam; \
		install -m644 pam_$${module}/pam_$${module}.8 $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/; \
	done
	$(call AFTER_BUILD)
endif

pam-modules-package: pam-modules-stage
	# pam-modules.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam-modules

	# pam-modules.mk Prep libpam-modules
	cp -a $(BUILD_STAGE)/pam-modules $(BUILD_DIST)/libpam-modules

	# pam-modules.mk Sign
	$(call SIGN,libpam-modules,general.xml)

	# pam-modules.mk Make .debs
	$(call PACK,libpam-modules,DEB_PAM-MODULES_V)

	# pam-modules.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam-modules

.PHONY: pam-modules pam-modules-package

endif
