ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


DISKDEV-CMDS_CF1900_VERSION := 697

diskdev-cmds_CF1900-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,diskdev_cmds,$(DISKDEV-CMDS_CF1900_VERSION),diskdev_cmds-$(DISKDEV-CMDS_CF1900_VERSION))
	$(call EXTRACT_TAR,diskdev_cmds-$(DISKDEV-CMDS_CF1900_VERSION).tar.gz,diskdev_cmds-diskdev_cmds-$(DISKDEV-CMDS_CF1900_VERSION),diskdev-cmds)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's/TARGET_OS_IPHONE/1/g' $(BUILD_WORK)/diskdev-cmds/edt_fstab/edt_fstab.h
	sed -i 's/TARGET_OS_SIMULATOR/0/g' $(BUILD_WORK)/diskdev-cmds/edt_fstab/edt_fstab.h
endif
	sed -i -e '/#include <TargetConditionals.h>/d' \
		$(BUILD_WORK)/diskdev-cmds/edt_fstab/edt_fstab.h \
		$(BUILD_WORK)/diskdev-cmds/fsck.tproj/fsck.c
	sed -i 's/TARGET_OS_IPHONE/WHOISJOE/g' \
		$(BUILD_WORK)/diskdev-cmds/fsck.tproj/fsck.c
	sed -i -e '/TARGET_OS_OSX/d' \
		$(BUILD_WORK)/diskdev-cmds/disklib/preen.c
	sed -i -e 's|/private/var/dirs_cleaner/|$(MEMO_PREFIX)/var/dirs_cleaner/|' \
		-e 's|/tmp|$(MEMO_PREFIX)/tmp|g' \
		$(BUILD_WORK)/diskdev-cmds/dirs_cleaner/dirs_cleaner.c
	mkdir -p $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{{s,}bin,libexec,share/man/man{1,5,8}}

ifneq ($(wildcard $(BUILD_WORK)/diskdev-cmds/.build_complete),)
diskdev-cmds_CF1900:
	@echo "Using previously built diskdev-cmds."
else
diskdev-cmds_CF1900: .SHELLFLAGS=-O extglob -c
diskdev-cmds_CF1900: diskdev-cmds-setup
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
		if [[ $$tproj = vsdbutil ]]; then \
			extra="${extra} mount_flags_dir/mount_flags.c"; \
		fi; \
		$(CC) $(CFLAGS) -isystem include -Idisklib -o $$tproj $$(find "$$tproj.tproj" -name '*.c') $(LDFLAGS) $${LIBDISKA} -lutil $$extra; \
	done
	cd $(BUILD_WORK)/diskdev-cmds/fstyp.tproj; \
	for c in *.c; do \
		bin=../$$(basename $$c .c); \
		$(CC) $(CFLAGS) $(LDFLAGS) -isystem ../include -o $$bin $$c; \
	done
	cd $(BUILD_WORK)/diskdev-cmds; \
	cp -a quota $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	cp -a dev_mkdb edquota fdisk quotaon repquota vsdbutil $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
	cp -a vndevice $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec; \
	cp -a quotacheck umount @(fstyp|newfs)?(_*([a-z0-9])) @(mount_*([a-z0-9])) $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
	cp -a quota.tproj/quota.1 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/; \
	cp -a mount.tproj/fstab.5 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/;
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
		rm -f $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/umount
endif
	$(call AFTER_BUILD)
endif

diskdev-cmds_CF1900-package:: DEB_DISKDEV-CMDS_V ?= $(DISKDEV-CMDS_CF1900_VERSION)
diskdev-cmds_CF1900-package: diskdev-cmds-stage
	# diskdev-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/diskdev-cmds

	# diskdev-cmds.mk Prep diskdev-cmds
	cp -a $(BUILD_STAGE)/diskdev-cmds $(BUILD_DIST)

	# diskdev-cmds.mk Sign
	$(call SIGN,diskdev-cmds,general.xml)

	# system-cmds.mk Permissions
ifneq (,$(findstring ramdisk,$(MEMO_TARGET)))
		$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/umount
endif

	# diskdev-cmds.mk Make .debs
	$(call PACK,diskdev-cmds,DEB_DISKDEV-CMDS_V)

	# diskdev-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/diskdev-cmds

.PHONY: diskdev-cmds_CF1900 diskdev-cmds_CF1900-package
