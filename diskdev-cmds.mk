ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS        += diskdev-cmds
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS          += diskdev-cmds
endif # ($(MEMO_TARGET),darwin-\*)
DISKDEV-CMDS_VERSION := 667.40.1
DEB_DISKDEV-CMDS_V   ?= $(DISKDEV-CMDS_VERSION)

diskdev-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/diskdev_cmds/diskdev_cmds-$(DISKDEV-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,diskdev_cmds-$(DISKDEV-CMDS_VERSION).tar.gz,diskdev_cmds-$(DISKDEV-CMDS_VERSION),diskdev-cmds)
	$(SED) -i -e '/#include <TargetConditionals.h>/d' \
		$(BUILD_WORK)/diskdev-cmds/edt_fstab/edt_fstab.h \
		$(BUILD_WORK)/diskdev-cmds/fsck.tproj/fsck.c
	$(SED) -i -e '/TARGET_OS_OSX/d' \
		$(BUILD_WORK)/diskdev-cmds/disklib/preen.c
	mkdir -p $(BUILD_STAGE)/diskdev-cmds/{usr/{{s,}bin,libexec,share/man/man{1,5,8}},sbin}

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/diskdev-cmds/include/{arm,machine,{System/,}sys,uuid}
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/{disk,reboot,vnioctl,vmmeter}.h $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h $(BUILD_WORK)/diskdev-cmds/include/sys
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{unistd,stdlib}.h $(BUILD_WORK)/diskdev-cmds/include

	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include \
		https://opensource.apple.com/source/libutil/libutil-57/mntopts.h \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/EXTERNAL_HEADERS/mach-o/nlist.h
	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include/arm \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/arm/disklabel.h
	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include/machine \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/machine/disklabel.h
	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include/sys \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/vnode.h
	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include/System/sys \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/bsd/sys/fsctl.h
	wget -q -nc -P $(BUILD_WORK)/diskdev-cmds/include/System/uuid \
		https://opensource.apple.com/source/Libc/Libc-1353.11.2/uuid/namespace.h

ifneq ($(wildcard $(BUILD_WORK)/diskdev-cmds/.build_complete),)
diskdev-cmds:
	@echo "Using previously built diskdev-cmds."
else
diskdev-cmds: .SHELLFLAGS=-O extglob -c
diskdev-cmds: diskdev-cmds-setup
	cd $(BUILD_WORK)/diskdev-cmds/disklib; \
	rm -f mntopts.h getmntopts.c; \
	for arch in $(MEMO_ARCH); do \
		for c in *.c; do \
			$(CC) -arch $${arch} -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem ../include -fno-common -o $$(basename $${c} .c)-$${arch}.o -c $${c}; \
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
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -DTARGET_OS_SIMULATOR -Idisklib -o $$tproj $$(find "$$tproj.tproj" -name '*.c') $${LIBDISKA} -lutil $$extra; \
	done
	cd $(BUILD_WORK)/diskdev-cmds/fstyp.tproj; \
	for c in *.c; do \
		bin=../$$(basename $$c .c); \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem ../include -o $$bin $$c; \
	done
	cd $(BUILD_WORK)/diskdev-cmds; \
	cp -a quota $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	cp -a dev_mkdb edquota fdisk quotaon repquota vsdbutil $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin; \
	cp -a vndevice $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec; \
	cp -a quotacheck umount @(fstyp|newfs)?(_*([a-z0-9])) @(mount_*([a-z0-9])) $(BUILD_STAGE)/diskdev-cmds/sbin; \
	cp -a quota.tproj/quota.1 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	cp -a mount.tproj/fstab.5 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5; \
	cp -a !(setclass).tproj/*.8 $(BUILD_STAGE)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
	rm -f $(BUILD_STAGE)/diskdev-cmds/sbin/umount
endif
	touch $(BUILD_WORK)/diskdev-cmds/.build_complete
endif

diskdev-cmds-package: diskdev-cmds-stage
	# diskdev-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/diskdev-cmds

	# diskdev-cmds.mk Prep diskdev-cmds
	cp -a $(BUILD_STAGE)/diskdev-cmds $(BUILD_DIST)

	# diskdev-cmds.mk Sign
	$(call SIGN,diskdev-cmds,general.xml)

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/quota
ifneq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/diskdev-cmds/sbin/umount
endif

	# diskdev-cmds.mk Make .debs
	$(call PACK,diskdev-cmds,DEB_DISKDEV-CMDS_V)

	# diskdev-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/diskdev-cmds

.PHONY: diskdev-cmds diskdev-cmds-package
