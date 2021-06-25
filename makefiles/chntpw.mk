ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += chntpw
CHNTPW_VERSION := 1.0
DEB_CHNTPW_V   ?= $(CHNTPW_VERSION)

chntpw-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/c/chntpw/chntpw_$(CHNTPW_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,chntpw_$(CHNTPW_VERSION).orig.tar.gz,chntpw-$(CHNTPW_VERSION),chntpw)
	$(SED) -i 's@/usr@$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)@g' $(BUILD_WORK)/chntpw/Makefile
	$(SED) -i 's|gcc|$(CC) $(CFLAGS)|g' $(BUILD_WORK)/chntpw/Makefile
	$(SED) -i 's/-m32//g' $(BUILD_WORK)/chntpw/Makefile
	$(SED) -i '1 i\#include <TargetConditionals.h>' $(BUILD_WORK)/chntpw/{cpnt,chntpw,sampasswd,samusrgrp}.c

ifneq ($(wildcard $(BUILD_WORK)/chntpw/.build_complete),)
chntpw:
	@echo "Using previously built chntpw."
else
chntpw: chntpw-setup
	$(MAKE) -C $(BUILD_WORK)/chntpw chntpw cpnt reged samusrgrp sampasswd
	mkdir -p $(BUILD_STAGE)/chntpw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(GINSTALL) -Dm755 $(BUILD_WORK)/chntpw/{chntpw,cpnt,reged,samusrgrp,sampasswd} $(BUILD_STAGE)/chntpw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/chntpw/.build_complete
endif

chntpw-package: chntpw-stage
	# chntpw.mk Package Structure
	rm -rf $(BUILD_DIST)/chntpw
	mkdir -p $(BUILD_DIST)/chntpw
	
	# chntpw.mk Prep chntpw
	cp -a $(BUILD_STAGE)/chntpw $(BUILD_DIST)
	
	# chntpw.mk Sign
	$(call SIGN,chntpw,general.xml)
	
	# chntpw.mk Make .debs
	$(call PACK,chntpw,DEB_CHNTPW_V)
	
	# chntpw.mk Build cleanup
	rm -rf $(BUILD_DIST)/chntpw

.PHONY: chntpw chntpw-package
