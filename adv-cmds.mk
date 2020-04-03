ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ADV-CMDS_VERSION := 174.0.1
DEB_ADV-CMDS_V   ?= $(ADV-CMDS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/adv-cmds/.build_complete),)
adv-cmds:
	@echo "Using previously built adv-cmds."
else
adv-cmds: setup ncurses
	mkdir -p $(BUILD_STAGE)/adv-cmds/usr/bin
	cd $(BUILD_WORK)/adv-cmds ; \
	$(CXX) $(CXXFLAGS) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/usr/bin/locale locale/*.cc; \
	$(CC) $(CFLAGS) -L $(BUILD_BASE)/usr/lib -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/usr/bin/tabs tabs/*.c -lncursesw; \
	for bin in finger last lsvfs cap_mkdb; do \
    	$(CC) $(CFLAGS) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/usr/bin/$$bin $$bin/*.c -D'__FBSDID(x)='; \
	done
	touch $(BUILD_WORK)/adv-cmds/.build_complete
endif

adv-cmds-package: adv-cmds-stage
	# adv-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/adv-cmds
	
	# adv-cmds.mk Prep adv-cmds
	$(FAKEROOT) cp -a $(BUILD_STAGE)/adv-cmds $(BUILD_DIST)

	# adv-cmds.mk Sign
	$(call SIGN,adv-cmds,general.xml)
	
	# adv-cmds.mk Make .debs
	$(call PACK,adv-cmds,DEB_ADV-CMDS_V)
	
	# adv-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/adv-cmds

.PHONY: adv-cmds adv-cmds-package
