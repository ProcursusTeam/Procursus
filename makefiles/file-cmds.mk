ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS     += file-cmds
# Don't upgrade file-cmds, as any future version includes APIs introduced in iOS 13+.
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
FILE-CMDS_VERSION := 272.250.1
DEB_FILE-CMDS_V   ?= $(FILE-CMDS_VERSION)-3
else
FILE-CMDS_VERSION := 353.100.22
DEB_FILE-CMDS_V   ?= $(FILE-CMDS_VERSION)
endif

file-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,file_cmds,$(FILE-CMDS_VERSION),file_cmds-$(FILE-CMDS_VERSION))
	$(call EXTRACT_TAR,file_cmds-$(FILE-CMDS_VERSION).tar.gz,file_cmds-file_cmds-$(FILE-CMDS_VERSION),file-cmds)
	mkdir -p $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,8}}
	mkdir -p $(BUILD_WORK)/file-cmds/ipcs/sys
	@wget -q -nc -P $(BUILD_WORK)/file-cmds/ipcs/sys \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8020.101.4/bsd/sys/{shm_internal,sem_internal,ipcs}.h
	sed -i 's/user64_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	sed -i 's/user32_time_t/user_time_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/sem_internal.h
	sed -i 's/user32_addr_t/user_addr_t/g' $(BUILD_WORK)/file-cmds/ipcs/sys/shm_internal.h
	sed -i 's/#include <nlist.h>/#include <mach-o\/nlist.h>/g' $(BUILD_WORK)/file-cmds/ipcs/ipcs.c

ifneq ($(wildcard $(BUILD_WORK)/file-cmds/.build_complete),)
file-cmds:
	@echo "Using previously built file-cmds."
else
file-cmds: file-cmds-setup
	cd $(BUILD_WORK)/file-cmds; \
	for bin in chflags compress ipcrm ipcs pax xattr; do \
		echo $${bin}; \
		$(CC) $(CFLAGS) -isystem include -o $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c $(LDFLAGS) -D'__FBSDID(x)=' -D__POSIX_C_SOURCE; \
		$(INSTALL) -Dm644 $$bin/$$bin.1 $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/; \
	done; \
	echo rmt && $(CC) $(CFLAGS) -isystem include -o $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rmt rmt/*.c $(LDFLAGS) -D'__FBSDID(x)=' -D__POSIX_C_SOURCE; \
		$(INSTALL) -Dm644 rmt/rmt.8 $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/; \
	echo shar && $(INSTALL) -Dm755 shar/shar.sh $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/shar; \
		$(INSTALL) -Dm644 shar/shar.1 $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/; \
	$(call AFTER_BUILD)
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
