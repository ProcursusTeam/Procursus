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
	for module in group launchd rootok sacl self uwtmp; do \
		echo $${module}; \
		$(CC) $(CFLAGS) -bundle -o pam_$${module}.so pam_$${module}/*.c $(LDFLAGS) -lpam || true; \
		cp -a pam_$${module}.so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam; \
	done
	cd $(BUILD_STAGE)/openpam/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam; \
	for so in *.2.so; do \
		cp -a $$so $(BUILD_STAGE)/pam-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam/$${so//".2"/}; \
	done
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