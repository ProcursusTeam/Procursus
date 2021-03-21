ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += pam-modules
PAM-MODULES_VERSION := 186.60.1
DEB_PAM-MODULES_V   ?= $(PAM-MODULES_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

pam-modules-setup: setup
	-wget -q -nc -P$(BUILD_SOURCE) https://opensource.apple.com/tarballs/pam_modules/pam_modules-$(PAM-MODULES_VERSION).tar.gz
	$(call EXTRACT_TAR,pam_modules-$(PAM-MODULES_VERSION).tar.gz,pam_modules-$(PAM-MODULES_VERSION),pam-modules)
	mkdir -p $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	
ifneq ($(wildcard $(BUILD_WORK)/pam-modules/.build_complete),)
pam-modules:
	@echo "Using previously built pam-modules."
else
pam-modules: pam-modules-setup openpam
	set -e; \
	cd $(BUILD_WORK)/pam-modules/modules; \
	for module in group launchd rootok self uwtmp; do \
		echo $${module}; \
		$(CC) -shared -o pam_$${module}.2.so pam_$${module}/*.c -lpam -I$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include || true; \
		cp -a pam_$${module}.2.so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam; \
	done
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam/*.2.so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	touch $(BUILD_WORK)/pam-modules/.build_complete
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