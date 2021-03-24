ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += pam-biometric
PAM-BIOMETRIC_VERSION := 1.0.0
DEB_PAM-BIOMETRIC_V   ?= $(PAM-BIOMETRIC_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

pam-biometric-setup: setup
	-wget -q -nc -O $(BUILD_SOURCE)/pam-biometric-$(PAM-BIOMETRIC_VERSION).tar.gz https://github.com/ProcursusTeam/pam-biometrics/archive/refs/tags/$(PAM-BIOMETRIC_VERSION).tar.gz
	$(call EXTRACT_TAR,pam-biometric-$(PAM-BIOMETRIC_VERSION).tar.gz,pam-biometric-$(PAM-BIOMETRIC_VERSION),pam-biometric)
	mkdir -p $(BUILD_STAGE)/pam-biometric/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	
ifneq ($(wildcard $(BUILD_WORK)/pam-biometric/.build_complete),)
pam-biometric:
	@echo "Using previously built pam-biometric."
else
pam-biometric: pam-biometric-setup openpam
	+cd $(BUILD_WORK)/pam-biometric && \
	$(MAKE) all && \
	$(GINSTALL) -Dm755 pam-biometric.so $(BUILD_STAGE)/pam-biometric/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	touch $(BUILD_WORK)/pam-biometric/.build_complete
endif

pam-biometric-package: pam-biometric-stage
	# pam-biometric.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam-biometric
	
	# pam-biometric.mk Prep libpam-biometric
	cp -a $(BUILD_STAGE)/pam-biometric $(BUILD_DIST)
	
	# pam-biometric.mk Sign
	$(call SIGN,libpam-biometric,general.xml)
	
	# pam-biometric.mk Make .debs
	$(call PACK,libpam-biometric,DEB_PAM-BIOMETRIC_V)
	
	# pam-biometric.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam-biometric

.PHONY: pam-biometric pam-biometric-package

endif
