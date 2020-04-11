ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SHELL-CMDS_VERSION := 207.40.1
DEB_SHELL-CMDS_V   ?= $(SHELL-CMDS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/shell-cmds/.build_complete),)
shell-cmds:
	@echo "Using previously built shell-cmds."
else
shell-cmds: setup
	mkdir -p $(BUILD_STAGE)/shell-cmds/usr/bin

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/shell-cmds/include/sys
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/user.h $(BUILD_WORK)/shell-cmds/include/sys

	cd $(BUILD_WORK)/shell-cmds ; \
	for bin in killall renice script time which getopt what; do \
    	$(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -isystem include -o $(BUILD_STAGE)/shell-cmds/usr/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -save-temps ; \
	done
	touch $(BUILD_WORK)/shell-cmds/.build_complete
endif

shell-cmds-package: shell-cmds-stage
	# shell-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/shell-cmds
	
	# shell-cmds.mk Prep shell-cmds
	$(FAKEROOT) cp -a $(BUILD_STAGE)/shell-cmds $(BUILD_DIST)

	# shell-cmds.mk Sign
	$(call SIGN,shell-cmds,general.xml)
	
	# shell-cmds.mk Make .debs
	$(call PACK,shell-cmds,DEB_SHELL-CMDS_V)
	
	# shell-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/shell-cmds

.PHONY: shell-cmds shell-cmds-package
