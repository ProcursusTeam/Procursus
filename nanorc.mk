ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nanorc
NANORC_VERSION := 1.0-$(shell cd nanorc && git log -n1 --format=format:"%H")
DEB_NANORC_V   ?= $(NANORC_VERSION)

nanorc-setup: setup
	rm -rf $(BUILD_WORK)/nanorc
	mkdir -p $(BUILD_WORK)/nanorc
	cp -af nanorc/* $(BUILD_WORK)/nanorc

ifneq ($(wildcard $(BUILD_WORK)/nanorc/.build_complete),)
nanorc:
	@echo "Using previously built nanorc."
else
nanorc: nanorc-setup nano
	mkdir -p $(BUILD_STAGE)/nanorc/var/mobile/.nano $(BUILD_STAGE)/nanorc/var/root
	echo "include /var/mobile/.nano/*.nanorc" >> $(BUILD_STAGE)/nanorc/var/mobile/.nanorc
	cp -af $(BUILD_STAGE)/nanorc/var/mobile/.nanorc $(BUILD_STAGE)/nanorc/var/root/.nanorc
	cp -af $(BUILD_WORK)/nanorc/*.nanorc $(BUILD_STAGE)/nanorc/var/mobile/.nano
	touch $(BUILD_WORK)/nanorc/.build_complete
endif

nanorc-package: nanorc-stage
	# nanorc.mk Package Structure
	rm -rf $(BUILD_DIST)/nanorc
	mkdir -p $(BUILD_DIST)/nanorc
	
	# nanorc.mk Prep nanorc
	cp -a $(BUILD_STAGE)/nanorc/var $(BUILD_DIST)/nanorc
	
	# nanorc.mk Make .debs
	$(call PACK,nanorc,DEB_NANORC_V)
	
	# nanorc.mk Build cleanup
	rm -rf $(BUILD_DIST)/nanorc

.PHONY: nanorc nanorc-package
