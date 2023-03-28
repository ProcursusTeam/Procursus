ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

DISKDEV-CMDS_CFBASE_VERSION := 593

diskdev-cmds_CFbase-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,diskdev_cmds,$(DISKDEV-CMDS_CFBASE_VERSION),diskdev_cmds-$(DISKDEV-CMDS_CFBASE_VERSION))
	$(call EXTRACT_TAR,diskdev_cmds-$(DISKDEV-CMDS_CFBASE_VERSION).tar.gz,diskdev_cmds-diskdev_cmds-$(DISKDEV-CMDS_CFBASE_VERSION),diskdev-cmds)
	sed -i -e '/#include <TargetConditionals.h>/d' \
		$(BUILD_WORK)/diskdev-cmds/fsck.tproj/fsck.c
	sed -i 's/TARGET_OS_EMBEDDED/WHOISJOE/g' \
		$(BUILD_WORK)/diskdev-cmds/fsck.tproj/fsck.c
	sed -i -e '/TARGET_OS_OSX/d' \
		$(BUILD_WORK)/diskdev-cmds/disklib/preen.c
	mkdir -p $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{{s,}bin,libexec,share/man/man{1,5,8}}
	sed -i 's#char \*argv#//char \*argv#g' \
		$(BUILD_WORK)/diskdev-cmds/quota.tproj/quota.c \
		$(BUILD_WORK)/diskdev-cmds/disklib/preen.c
	sed -i 's/main(argc, argv)/main(int argc, char* argv[])/g' \
		$(BUILD_WORK)/diskdev-cmds/quota.tproj/quota.c \
		$(BUILD_WORK)/diskdev-cmds/disklib/preen.c
	sed -i -e 's/#define PROTECTION_CLASS_A 1/#ifndef O_DP_GETRAWENCRYPTED\n#define O_DP_GETRAWENCRYPTED 0x1\n#define open_dprotected_np(a,b,c...) open(a,b)\n#endif\n#define PROTECTION_CLASS_A 1/g' $(BUILD_WORK)/diskdev-cmds/setclass.tproj/setclass.c
	sed -i -e 's/select_fstyp,/\(int \(*\)\(struct dirent *\)\)select_fstyp,/g' $(BUILD_WORK)/diskdev-cmds/fstyp.tproj/fstyp.c
	

ifneq ($(wildcard $(BUILD_WORK)/diskdev-cmds/.build_complete),)
diskdev-cmds_CFbase:
	@echo "Using previously built diskdev-cmds."
else
diskdev-cmds_CFbase: .SHELLFLAGS=-O extglob -c
diskdev-cmds_CFbase: diskdev-cmds-setup
	cd $(BUILD_WORK)/diskdev-cmds/disklib; \
	rm -f mntopts.h getmntopts.c; \
	for arch in $(MEMO_ARCH); do \
		for c in *.c; do \
			$(CC) $(CFLAGS) -isystem ../include -fno-common -o $$(basename $${c} .c)-$${arch}.o -c $${c}; \
		done; \
		$(AR) -r libdisk-$${arch}.a *-$${arch}.o; \
		LIBDISKA=$$(echo disklib/libdisk-$${arch}.a $${LIBDISKA}); \
	done; \
	cd $(BUILD_WORK)/diskdev-cmds; \
	for tproj in !(fstyp|fsck_hfs|fuser|mount|mount_portal|mount_swapfs|mount_umap|newfs_hfs_debug).tproj; do \
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
		$(CC) $(CFLAGS) -isystem include -Idisklib -o $$tproj $$(find "$$tproj.tproj" -name '*.c') $(LDFLAGS) $${LIBDISKA} -lutil $$extra; \
	done
	cd $(BUILD_WORK)/diskdev-cmds/fstyp.tproj; \
	for c in *.c; do \
		bin=../$$(basename $$c .c); \
		$(CC) $(CFLAGS) $(LDFLAGS) -isystem ../include -o $$bin $$c; \
	done
	cd $(BUILD_WORK)/diskdev-cmds; \
	cp -a quota $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	cp -a dev_mkdb edquota fdisk quotaon repquota vsdbutil $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/; \
	cp -a vndevice $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/; \
	cp -a quotacheck umount @(fstyp|newfs)?(_*([a-z0-9])) @(mount_*([a-z0-9])) $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/; \
	cp -a quota.tproj/quota.1 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	cp -a mount.tproj/fstab.5 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5;
	$(call AFTER_BUILD)
endif

diskdev-cmds_CFbase-package:: DEB_DISKDEV-CMDS_V ?= $(DISKDEV-CMDS_CFBASE_VERSION)
diskdev-cmds_CFbase-package: diskdev-cmds-stage
	# diskdev-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/diskdev-cmds

	# diskdev-cmds.mk Prep diskdev-cmds
	cp -a $(BUILD_STAGE)/diskdev-cmds $(BUILD_DIST)

	# diskdev-cmds.mk Sign
	$(call SIGN,diskdev-cmds,general.xml)

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/quota
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/umount

	# diskdev-cmds.mk Make .debs
	$(call PACK,diskdev-cmds,DEB_DISKDEV-CMDS_V)

	# diskdev-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/diskdev-cmds
.PHONY: diskdev-cmds_CFbase diskdev-cmds-package_CFbase