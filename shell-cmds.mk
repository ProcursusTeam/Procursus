ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS      += shell-cmds
SHELL-CMDS_VERSION := 207.40.1
DEB_SHELL-CMDS_V   ?= $(SHELL-CMDS_VERSION)

shell-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/shell_cmds/shell_cmds-$(SHELL-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,shell_cmds-$(SHELL-CMDS_VERSION).tar.gz,shell_cmds-$(SHELL-CMDS_VERSION),shell-cmds)

ifneq ($(wildcard $(BUILD_WORK)/shell-cmds/.build_complete),)
shell-cmds:
	@echo "Using previously built shell-cmds."
else
shell-cmds: shell-cmds-setup
	mkdir -p $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/shell-cmds/include/sys
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/user.h $(BUILD_WORK)/shell-cmds/include/sys
	cp -a $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h $(BUILD_WORK)/shell-cmds/include

	cd $(BUILD_WORK)/shell-cmds; \
	$(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/hexdump hexdump/{conv,display,hexdump,hexsyntax,odsyntax,parse}.c -D'__FBSDID(x)=' -D__DARWIN_C_LEVEL=200112L; \
	for bin in killall renice script time which getopt what; do \
    	$(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -save-temps; \
	done
	touch $(BUILD_WORK)/shell-cmds/.build_complete
endif

shell-cmds-package: shell-cmds-stage
	# shell-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/shell-cmds
	
	# shell-cmds.mk Prep shell-cmds
	cp -a $(BUILD_STAGE)/shell-cmds $(BUILD_DIST)

	# shell-cmds.mk Sign
	$(call SIGN,shell-cmds,general.xml)
	
	# shell-cmds.mk Make .debs
	$(call PACK,shell-cmds,DEB_SHELL-CMDS_V)
	
	# shell-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/shell-cmds

.PHONY: shell-cmds shell-cmds-package
