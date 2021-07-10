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
	mkdir -p $(BUILD_STAGE)/file-cmds/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,sbin},$(MEMO_PREFIX)/{bin,sbin}} \
		$(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{1,8}
	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/file-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/tzfile.h $(BUILD_WORK)/file-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/get_compat.h \
		$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/unistd.h \
		$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libiosexec.h \
		$(BUILD_WORK)/file-cmds/include
ifeq ($(UNAME),FreeBSD)
	@# FreeBSD does not have stdbool.h and stdarg.h
	$(CP) -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Headers/{stdbool.h,stdarg.h} $(BUILD_WORK)/file-cmds/include
endif
	wget -nc -P$(BUILD_WORK)/file-cmds/include/os \
		https://opensource.apple.com/source/Libc/Libc-1439.40.11/os/assumes.h \
		https://opensource.apple.com/source/libplatform/libplatform-126.1.2/include/os/base_private.h
	wget -nc -P$(BUILD_WORK)/file-cmds/include/CommonCrypto \
		https://opensource.apple.com/source/CommonCrypto/CommonCrypto-60118.30.2/include/CommonDigestSPI.h
	wget -nc -P$(BUILD_WORK)/file-cmds/include/ \
		https://opensource.apple.com/source/libplatform/libplatform-126.1.2/include/_simple.h
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
	$(SED) -i 's/char \*chdname;/extern char *chdname;/' $(BUILD_WORK)/file-cmds/pax/extern.h
	$(SED) -i '67s/^/char *chdname;\n/' $(BUILD_WORK)/file-cmds/pax/options.c
	cd $(BUILD_WORK)/file-cmds ; \
	for bin in chflags compress ipcrm ipcs pax mtree mknod mkfifo; do \
		case $$bin in \
			mtree) EXTRAFLAGS="-DENABLE_MD5 -DENABLE_RMD160 -DENABLE_SHA1 -DENABLE_SHA256 $(BUILD_WORK)/file-cmds/cksum/crc.c";; \
			pax) EXTRAFLAGS="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiosexec.tbd";; \
		esac; \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -o $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c $$EXTRAFLAGS -D'__FBSDID(x)=' -D__POSIX_C_SOURCE; \
	done
	$(INSTALL) -Dm644 $(BUILD_WORK)/file-cmds/{chflags,compress,ipcrm,ipcs,pax,mkfifo}/*.1 $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	$(INSTALL) -Dm644 $(BUILD_WORK)/file-cmds/{mknod,mtree}/*.8 $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/
	rm $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/cpio.1
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chflags $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)/bin/chflags
	mv $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mtree $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/
	mv $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mknod $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)/sbin/
	mv $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pax $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)/bin/
	$(INSTALL) -Dm755 $(BUILD_WORK)/file-cmds/shar/shar.sh $(BUILD_STAGE)/file-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/shar
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
