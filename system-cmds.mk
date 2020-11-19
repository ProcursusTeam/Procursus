ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += system-cmds
SYSTEM-CMDS_VERSION := 854.40.2
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)-1

system-cmds-setup: setup libxcrypt
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/system_cmds/system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz,system_cmds-$(SYSTEM-CMDS_VERSION),system-cmds)
	$(call DO_PATCH,system-cmds,system-cmds,-p1)
	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/system-cmds/include/{IOKit,mach,sys}
	cp -a $(MACOSX_SYSROOT)/usr/include/{libkern,net,servers,xpc} $(BUILD_WORK)/system-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/{lib{c,proc},NSSystemDirectories,bootstrap,tzfile}.h $(BUILD_WORK)/system-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/{reboot,proc*,kern_control}.h $(BUILD_WORK)/system-cmds/include/sys
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_WORK)/system-cmds/include/IOKit
	cp -a $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{unistd,stdlib}.h $(BUILD_WORK)/system-cmds/include
	cp -a $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mach/{task,mach_host}.h $(BUILD_WORK)/system-cmds/include/mach
	cp -a $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/crypt.h $(BUILD_WORK)/system-cmds/include	

	wget -nc -P $(BUILD_WORK)/system-cmds/include \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/reboot2.h \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/bootstrap_priv.h \
		https://opensource.apple.com/source/xnu/xnu-6153.61.1/libsyscall/wrappers/spawn/spawn.h

	# Apple's chpass won't build so we used a modified freebsd version.
	rm -rf $(BUILD_WORK)/system-cmds/chpass.tproj && mkdir -p $(BUILD_WORK)/system-cmds/chpass.tproj
	wget -nc -P $(BUILD_WORK)/system-cmds/chpass.tproj \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/libutil.h \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/pw_util.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/flopen.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libc/gen/pw_scan.{c,h} \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/usr.bin/chpass/{chpass{.h,.c},edit.c,field.c,table.c,util.c}

	$(SED) -i '/#include <stdio.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	$(SED) -i '/#include <libutil.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/chpass.tproj/chpass.c

ifneq ($(wildcard $(BUILD_WORK)/system-cmds/.build_complete),)
system-cmds:
	@echo "Using previously built system-cmds."
else
system-cmds: system-cmds-setup
	for gperf in $(BUILD_WORK)/system-cmds/getconf.tproj/*.gperf; do \
	    LC_ALL=C awk -f $(BUILD_WORK)/system-cmds/getconf.tproj/fake-gperf.awk < $$gperf > $(BUILD_WORK)/system-cmds/getconf.tproj/"$$(basename $$gperf .gperf).c" ; \
	done

	rm -f $(BUILD_WORK)/system-cmds/passwd.tproj/{od,nis,pam}_passwd.c
	cd $(BUILD_WORK)/system-cmds && $(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o passwd passwd.tproj/*.c -isystem include $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrypt.dylib
	cd $(BUILD_WORK)/system-cmds && $(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o dmesg dmesg.tproj/*.c -isystem include 
	cd $(BUILD_WORK)/system-cmds && $(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o sysctl sysctl.tproj/sysctl.c -isystem include 
	cd $(BUILD_WORK)/system-cmds && $(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o arch arch.tproj/*.c -isystem include -framework CoreFoundation -framework Foundation -lobjc 

	cd $(BUILD_WORK)/system-cmds; \
	for tproj in ac accton chpass dynamic_pager getconf getty hostinfo iostat login mkfile pwd_mkdb reboot sync vifs vipw zdump zic nologin; do \
		CFLAGS=; \
		EXTRA=; \
		case $$tproj in \
			chpass) CFLAGS="-Ichpass.tproj" LDFLAGS="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrypt.dylib";; \
			login) LDFLAGS="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcrypt.dylib";; \
			dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) $(ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o $$tproj $$tproj.tproj/*.c -isystem include -D'__FBSDID(x)=' $$CFLAGS -F$(BUILD_BASE)/System/Library/Frameworks -framework CoreFoundation -framework IOKit $$LDFLAGS; \
	done

	mkdir -p $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX){/bin,/sbin,/$(MEMO_SUB_PREFIX)/bin,/$(MEMO_SUB_PREFIX)/sbin}

	cp -a $(BUILD_WORK)/system-cmds/{reboot,nologin} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize

	cp -a $(BUILD_WORK)/system-cmds/sync $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{dmesg,dynamic_pager} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin
	$(LN) -sf ../$(MEMO_SUB_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin/halt
	cp -a $(BUILD_WORK)/system-cmds/{arch,chpass,getconf,getty,hostinfo,login,passwd} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN) -sf chpass $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chfn
	$(LN) -sf chpass $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chsh
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds/usr/sbin
	touch $(BUILD_WORK)/system-cmds/.build_complete
endif

system-cmds-package: system-cmds-stage
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds

	# system-cmds.mk Prep system-cmds
	cp -a $(BUILD_STAGE)/system-cmds $(BUILD_DIST)

	# system-cmds.mk Sign
	$(call SIGN,system-cmds,general.xml)

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/system-cmds/usr/bin/{passwd,login}
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/system-cmds/usr/bin/pagesize

	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_V)

	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds system-cmds-package
