ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS     += file-cmds
# Don't upgrade file-cmds, as any future version includes APIs introduced in iOS 13+.
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
FILE-CMDS_VERSION := 272.250.1
else
FILE-CMDS_VERSION := 287.40.2
endif
DEB_FILE-CMDS_V   ?= $(FILE-CMDS_VERSION)-2

file-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/file_cmds/file_cmds-$(FILE-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,file_cmds-$(FILE-CMDS_VERSION).tar.gz,file_cmds-$(FILE-CMDS_VERSION),file-cmds)
	mkdir -p $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/file-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/tzfile.h $(BUILD_WORK)/file-cmds/include
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h $(BUILD_WORK)/file-cmds/include

	mkdir -p $(BUILD_WORK)/file-cmds/ipcs/sys
	wget -nc -P $(BUILD_WORK)/file-cmds/ipcs/sys \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/ipcs.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/sem_internal.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/shm_internal.h
	$(SED) -i 's/user64_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	$(SED) -i 's/user32_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	$(SED) -i 's/user32_addr_t/user_addr_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/shm_internal.h
	$(SED) -i 's/#include <nlist.h>/#include <mach-o\/nlist.h>/g' $(BUILD_WORK)/file-cmds/ipcs/ipcs.c

ifneq ($(wildcard $(BUILD_WORK)/file-cmds/.build_complete),)
file-cmds:
	@echo "Using previously built file-cmds."
else
file-cmds: file-cmds-setup
	cd $(BUILD_WORK)/file-cmds ; \
	for bin in chflags compress ipcrm ipcs pax; do \
	    	$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -o $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -D__POSIX_C_SOURCE; \
	done
	touch $(BUILD_WORK)/file-cmds/.build_complete
endif

file-cmds-package: file-cmds-stage
	# file-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/file-cmds

	# file-cmds.mk Prep file-cmds
	cp -a $(BUILD_STAGE)/file-cmds $(BUILD_DIST)

	# file-cmds.mk Sign
	$(call SIGN,file-cmds,general.xml)

	# file-cmds.mk Make .debs
	$(call PACK,file-cmds,DEB_FILE-CMDS_V)

	# file-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/file-cmds

.PHONY: file-cmds file-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)