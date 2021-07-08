ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS            += pam-biometrics
PAM-BIOMETRICS_VERSION := 1.1.4
DEB_PAM-BIOMETRICS_V   ?= $(PAM-BIOMETRICS_VERSION)-1

pam-biometrics-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,pam-biometrics,$(PAM-BIOMETRICS_VERSION),$(PAM-BIOMETRICS_VERSION))
	$(call EXTRACT_TAR,pam-biometrics-$(PAM-BIOMETRICS_VERSION).tar.gz,pam-biometrics-$(PAM-BIOMETRICS_VERSION),pam-biometrics)
	mkdir -p $(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/man/man8,lib/pam}

ifneq ($(wildcard $(BUILD_WORK)/pam-biometrics/.build_complete),)
pam-biometrics:
	@echo "Using previously built pam-biometrics."
else
pam-biometrics: pam-biometrics-setup openpam
	+$(MAKE) -C $(BUILD_WORK)/pam-biometrics all
	$(INSTALL) -Dm755 $(BUILD_WORK)/pam-biometrics/pam_biometrics.so $(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	wget -q -O$(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/pam_biometrics.8 https://gist.githubusercontent.com/1Conan/992efca8fb1ac1551432b7a744817faf/raw/b304293cd378aefbcceb22d427794f2777f09088/pam-biometrics.8.txt
	ln -s pam_biometrics.so $(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam/pam-biometrics.so
	# Leave the above symlink for compatibility with a messup I originally made when pushing this.
	touch $(BUILD_WORK)/pam-biometrics/.build_complete
endif

pam-biometrics-package: pam-biometrics-stage
	# pam-biometrics.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam-biometrics

	# pam-biometrics.mk Prep libpam-biometrics
	cp -a $(BUILD_STAGE)/pam-biometrics $(BUILD_DIST)/libpam-biometrics

	# pam-biometrics.mk Sign
	$(call SIGN,libpam-biometrics,general.xml)

	# pam-biometrics.mk Make .debs
	$(call PACK,libpam-biometrics,DEB_PAM-BIOMETRICS_V)

	# pam-biometrics.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam-biometrics

.PHONY: pam-biometrics pam-biometrics-package

endif
