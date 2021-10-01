ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += msdosfs
MSDOSFS_VERSION := 435.60.1
DEB_MSDOSFS_V   ?= $(MSDOSFS_VERSION)

msdosfs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/msdosfs/msdosfs-$(MSDOSFS_VERSION).tar.gz
	$(call EXTRACT_TAR,msdosfs-$(MSDOSFS_VERSION).tar.gz,msdosfs-$(MSDOSFS_VERSION),msdosfs)
	mkdir -p $(BUILD_STAGE)/msdosfs/$(MEMO_PREFIX)/{sbin,$(MEMO_SUB_PREFIX)/share/man/man8}
	mkdir -p $(BUILD_WORK)/msdosfs/include/{sys,machine}
	wget -q -nc -P $(BUILD_WORK)/msdosfs/include \
		https://opensource.apple.com/source/libutil/libutil-58.40.2/{mntopts,wipefs}.h
	cp -af $(MACOSX_SYSROOT)/usr/include/sys/loadable_fs.h $(BUILD_WORK)/msdosfs/include/sys
	cp -af $(MACOSX_SYSROOT)/usr/include/machine/byte_order.h $(BUILD_WORK)/msdosfs/include/machine
	$(LN_S) $(BUILD_WORK)/msdosfs/msdos{_,.}util.tproj

ifneq ($(wildcard $(BUILD_WORK)/msdosfs/.build_complete),)
msdosfs:
	@echo "Using previously built msdosfs."
else
msdosfs: msdosfs-setup
	cd $(BUILD_WORK)/msdosfs; \
	for tproj in fsck_msdos mount_msdos msdos.util newfs_msdos; do \
		cd $$tproj.tproj && echo $$tproj; \
		$(CC) $(CFLAGS) $(LDFLAGS) -framework CoreFoundation -framework IOKit -I../include -lutil -o $(BUILD_STAGE)/msdosfs/$(MEMO_PREFIX)/sbin/$$tproj *.c; \
		cp -af $$tproj.8 $(BUILD_STAGE)/msdosfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8; \
		cd ..; \
	done
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	rm -f $(BUILD_STAGE)/msdosfs/$(MEMO_PREFIX)/sbin/{mount,fsck}_msdos
	rm -f $(BUILD_STAGE)/msdosfs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/mount_msdos.8
endif
	$(call AFTER_BUILD)
endif

msdosfs-package: msdosfs-stage
	# msdosfs.mk Package Structure
	rm -rf $(BUILD_DIST)/msdosfs

	# msdosfs.mk Prep msdosfs
	cp -a $(BUILD_STAGE)/msdosfs $(BUILD_DIST)

	# msdosfs.mk Sign
	$(call SIGN,msdosfs,msdosfs.xml)

	# msdosfs.mk Make .debs
	$(call PACK,msdosfs,DEB_MSDOSFS_V)

	# msdosfs.mk Build cleanup
	rm -rf $(BUILD_DIST)/msdosfs

.PHONY: msdosfs msdosfs-package
