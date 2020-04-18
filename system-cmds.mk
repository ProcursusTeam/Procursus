ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS       += system-cmds
SYSTEM-CMDS_VERSION := 854.40.2
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)

system-cmds-setup: setup
	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p system-cmds/include/{IOKit,sys}
	cp -a $(MACOSX_SYSROOT)/usr/include/{libkern,net,servers,xpc} system-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/{lib{c,proc},NSSystemDirectories,bootstrap,tzfile}.h system-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/sys/{reboot,proc*,kern_control}.h system-cmds/include/sys
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* system-cmds/include/IOKit
	cp -a $(BUILD_BASE)/usr/include/stdlib.h system-cmds/include
	
	wget -nc -P system-cmds/include \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/reboot2.h \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/bootstrap_priv.h

	# Apple's chpass won't build so we used a modified freebsd version.
	rm -rf system-cmds/chpass.tproj && mkdir -p system-cmds/chpass.tproj
	wget -nc -P system-cmds/chpass.tproj \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/libutil.h \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/pw_util.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/flopen.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libc/gen/pw_scan.{c,h} \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/usr.bin/chpass/{chpass{.h,.c},edit.c,field.c,table.c,util.c}

ifneq ($(wildcard system-cmds/.build_complete),)
system-cmds:
	@echo "Using previously built system-cmds."
else
system-cmds: system-cmds-setup
	for gperf in system-cmds/getconf.tproj/*.gperf; do \
	    LC_ALL=C awk -f system-cmds/getconf.tproj/fake-gperf.awk < $$gperf > system-cmds/getconf.tproj/"$$(basename $$gperf .gperf).c" ; \
	done
	
	rm -f system-cmds/passwd.tproj/od_passwd.c
	cd system-cmds && $(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -std=c89 -o passwd passwd.tproj/*.c -isystem include
	cd system-cmds && $(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -o dmesg dmesg.tproj/*.c -isystem include 
	cd system-cmds && $(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -o sysctl sysctl.tproj/sysctl.c -isystem include 
	cd system-cmds && $(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -o arch arch.tproj/*.c -isystem include -framework CoreFoundation -framework Foundation -lobjc 
	
	cd system-cmds; \
	for tproj in ac accton chpass dynamic_pager getconf getty hostinfo iostat login mkfile pwd_mkdb reboot sync vifs vipw zdump zic nologin; do \
		CFLAGS=; \
		EXTRA=; \
		case $$tproj in \
			chpass) CFLAGS="-Ichpass.tproj";; \
			dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) -arch $(ARCH) -isysroot $(SYSROOT) $($(PLATFORM)_VERSION_MIN) -o $$tproj $$tproj.tproj/*.c -isystem include -D'__FBSDID(x)=' -framework CoreFoundation -framework IOKit $$CFLAGS; \
	done
	
	mkdir -p $(BUILD_STAGE)/system-cmds/{/bin,/sbin,/usr/bin,/usr/sbin}

	cp -a system-cmds/{reboot,nologin} $(BUILD_STAGE)/system-cmds/usr/sbin
	cp -a system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds/usr/bin/pagesize

	cp -a system-cmds/sync $(BUILD_STAGE)/system-cmds/bin
	cp -a system-cmds/{dmesg,dynamic_pager} $(BUILD_STAGE)/system-cmds/sbin
	$(LN) -sf ../usr/sbin/reboot $(BUILD_STAGE)/system-cmds/sbin/halt
	cp -a system-cmds/{arch,chpass,getconf,getty,hostinfo,login,passwd} $(BUILD_STAGE)/system-cmds/usr/bin
	$(LN) -sf chpass $(BUILD_STAGE)/system-cmds/usr/bin/chfn
	$(LN) -sf chpass $(BUILD_STAGE)/system-cmds/usr/bin/chsh
	cp -a system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds/usr/sbin
	touch system-cmds/.build_complete
endif

system-cmds-package: system-cmds-stage
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds
	
	# system-cmds.mk Prep system-cmds
	$(FAKEROOT) cp -a $(BUILD_STAGE)/system-cmds $(BUILD_DIST)

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
