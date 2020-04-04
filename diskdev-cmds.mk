ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DISKDEV-CMDS_VERSION := 593.230.1
DEB_DISKDEV-CMDS_V   ?= $(DISKDEV-CMDS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/diskdev-cmds/.build_complete),)
diskdev-cmds:
	@echo "Using previously built diskdev-cmds."
else
diskdev-cmds: .SHELLFLAGS=-O extglob -c
diskdev-cmds: setup
	mkdir -p $(BUILD_STAGE)/diskdev-cmds/{usr/{{s,}bin,libexec},sbin}
	#$(SED) -i 's/get_fsent/getfsent/g' $(BUILD_WORK)/diskdev-cmds/umount.tproj/umount.c
	#$(SED) -i 's/setup_fsent/setfsent/g' $(BUILD_WORK)/diskdev-cmds/umount.tproj/umount.c
	cd $(BUILD_WORK)/diskdev-cmds/disklib; \
	rm -f mntopts.h getmntopts.c; \
	$(CC) $(CFLAGS) -fno-common -c *.c; \
	$(AR) -r libdisk.a *.o
	cd $(BUILD_WORK)/diskdev-cmds; \
	for tproj in !(fstyp|fsck_hfs|fuser|mount_portal|mount_swapfs|mount_umap|newfs_hfs_debug).tproj; do \
		tproj=$$(basename $$tproj .tproj); \
		echo $$tproj; \
		extra=; \
		if [[ $$tproj = restore ]]; then \
			extra="${extra} -DRRESTORE"; \
		fi; \
		if [[ $$tproj = mount_cd9660 || $$tproj = mount_hfs ]]; then \
			extra="${extra} -framework IOKit"; \
		fi; \
		if [[ $$tproj = mount_cd9660 || $$tproj = mount_hfs || $$tproj = newfs_hfs ]]; then \
			extra="${extra} -framework CoreFoundation"; \
		fi; \
    	$(CC) $(CFLAGS) -DTARGET_OS_SIMULATOR -Idisklib -o $$tproj $$(find "$$tproj.tproj" -name '*.c') disklib/libdisk.a -lutil $$extra; \
	done
	cd $(BUILD_WORK)/diskdev-cmds/fstyp.tproj; \
	for c in *.c; do \
    	bin=../$$(basename $$c .c); \
    	$(CC) $(CFLAGS) -o $$bin $$c; \
	done
	cd $(BUILD_WORK)/diskdev-cmds; \
	cp -a quota $(BUILD_STAGE)/diskdev-cmds/usr/bin; \
	cp -a dev_mkdb edquota fdisk quotaon repquota vsdbutil $(BUILD_STAGE)/diskdev-cmds/usr/sbin; \
	cp -a vndevice $(BUILD_STAGE)/diskdev-cmds/usr/libexec; \
	cp -a quotacheck umount @(fstyp|newfs)?(_*([a-z0-9])) @(mount_*([a-z0-9])) $(BUILD_STAGE)/diskdev-cmds/sbin
	touch $(BUILD_WORK)/diskdev-cmds/.build_complete
endif

diskdev-cmds-package: diskdev-cmds-stage
	# diskdev-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/diskdev-cmds
	
	# diskdev-cmds.mk Prep diskdev-cmds
	$(FAKEROOT) cp -a $(BUILD_STAGE)/diskdev-cmds $(BUILD_DIST)

	# diskdev-cmds.mk Sign
	$(call SIGN,diskdev-cmds,general.xml)

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/{usr/bin/quota,sbin/umount}
	
	# diskdev-cmds.mk Make .debs
	$(call PACK,diskdev-cmds,DEB_DISKDEV-CMDS_V)
	
	# diskdev-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/diskdev-cmds

.PHONY: diskdev-cmds diskdev-cmds-package
