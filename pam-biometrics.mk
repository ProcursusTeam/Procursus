ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS            += pam-biometrics
PAM-BIOMETRICS_VERSION := 1.1.0
DEB_PAM-BIOMETRICS_V   ?= $(PAM-BIOMETRICS_VERSION)

pam-biometrics-setup: setup
	-wget -q -nc -O$(BUILD_SOURCE)/pam-biometrics-$(PAM-BIOMETRICS_VERSION).tar.gz https://github.com/ProcursusTeam/pam-biometrics/archive/refs/tags/$(PAM-BIOMETRICS_VERSION).tar.gz
	$(call EXTRACT_TAR,pam-biometrics-$(PAM-BIOMETRICS_VERSION).tar.gz,pam-biometrics-$(PAM-BIOMETRICS_VERSION),pam-biometrics)
	mkdir -p $(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	
ifneq ($(wildcard $(BUILD_WORK)/pam-biometrics/.build_complete),)
pam-biometrics:
	@echo "Using previously built pam-biometrics."
else
pam-biometrics: pam-biometrics-setup openpam
	+$(MAKE) -C $(BUILD_WORK)/pam-biometrics all
	$(GINSTALL) -Dm755 $(BUILD_WORK)/pam-biometrics/pam-biometrics.so $(BUILD_STAGE)/pam-biometrics/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
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
