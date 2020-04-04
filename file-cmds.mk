ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

FILE-CMDS_VERSION := 287.40.2
DEB_FILE-CMDS_V   ?= $(FILE-CMDS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/file-cmds/.build_complete),)
file-cmds:
	@echo "Using previously built file-cmds."
else
file-cmds: setup
	mkdir -p $(BUILD_STAGE)/file-cmds/usr/bin
	mkdir -p $(BUILD_WORK)/file-cmds/ipcs/sys
	wget -nc -P $(BUILD_WORK)/file-cmds/ipcs/sys \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/ipcs.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/sem_internal.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/shm_internal.h
	$(SED) -i 's/user64_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	$(SED) -i 's/user32_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	$(SED) -i 's/user32_addr_t/user_addr_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/shm_internal.h
	$(SED) -i 's/#include <nlist.h>/#include <mach-o\/nlist.h>/g' $(BUILD_WORK)/file-cmds/ipcs/ipcs.c
	cd $(BUILD_WORK)/file-cmds ; \
	for bin in chflags compress ipcrm ipcs pax; do \
    	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/file-cmds/usr/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -D__POSIX_C_SOURCE; \
	done
	touch $(BUILD_WORK)/file-cmds/.build_complete
endif

file-cmds-package: file-cmds-stage
	# file-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/file-cmds
	
	# file-cmds.mk Prep file-cmds
	$(FAKEROOT) cp -a $(BUILD_STAGE)/file-cmds $(BUILD_DIST)

	# file-cmds.mk Sign
	$(call SIGN,file-cmds,general.xml)
	
	# file-cmds.mk Make .debs
	$(call PACK,file-cmds,DEB_FILE-CMDS_V)
	
	# file-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/file-cmds

.PHONY: file-cmds file-cmds-package
