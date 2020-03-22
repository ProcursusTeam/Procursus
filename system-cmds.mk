ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SYSTEM-CMDS_VERSION := 854.11.2
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)

# For system-cmds, there is a required libc.h header not included in sdks. Simply

ifneq ($(wildcard system-cmds/.build_complete),)
system-cmds:
	@echo "Using previously built system-cmds."
else
system-cmds: setup
	# This hack makes me extremely sad. System-cmds won't build without these libkern headers, but they interfere with iOS headers usually.
	mv $(BUILD_BASE)/usr/include/libkern.bad $(BUILD_BASE)/usr/include/libkern
	mkdir -p system-cmds/chpass
	wget -nc -P system-cmds/chpass \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/libutil.h \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/pw_util.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libutil/flopen.c \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/lib/libc/gen/pw_scan.{c,h} \
		https://raw.githubusercontent.com/coolstar/freebsd-ports-ios/master/usr.bin/chpass/{chpass{.h,.c},edit.c,field.c,table.c,util.c}
	cd system-cmds/chpass && $(CC) $(CFLAGS) -I. *.c -o chpass

	for gperf in system-cmds/getconf.tproj/*.gperf; do \
	    LC_ALL=C awk -f system-cmds/getconf.tproj/fake-gperf.awk < $$gperf > system-cmds/getconf.tproj/"$$(basename $$gperf .gperf).c" ; \
	done
	
	rm -f system-cmds/passwd.tproj/od_passwd.c
	cd system-cmds && $(CC) -std=c89 -o passwd passwd.tproj/*.c -I. -DTARGET_OS_EMBEDDED $(CFLAGS)
	cd system-cmds && $(CC) -o dmesg dmesg.tproj/*.c -I. $(CFLAGS)
	cd system-cmds && $(CC) -o sysctl sysctl.tproj/sysctl.c -I. $(CFLAGS)
	cd system-cmds && $(CC) -o arch arch.tproj/*.c -I. -framework CoreFoundation -framework Foundation -lobjc $(CFLAGS)
	
	for tproj in system-cmds/{ac,accton,dynamic_pager,getconf,getty,hostinfo,iostat,login,mkfile,pwd_mkdb,reboot,sync,vifs,vipw,zdump,zic,nologin}; do \
		CFLAGS= ; \
		case $$tproj in \
			system-cmds/dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			system-cmds/kvm_mkdb) CFLAGS="-DBSD_KERNEL_PRIVATE";; \
			system-cmds/pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) -o $$tproj $$tproj.tproj/*.c -I. -D'__FBSDID(x)=' -DTARGET_OS_EMBEDDED -framework CoreFoundation -framework IOKit $(CFLAGS) $$CFLAGS ; \
	done

	chmod u+s system-cmds/{passwd,login}
	
	mkdir -p $(BUILD_STAGE)/system-cmds/{/bin,/sbin,/usr/bin,/usr/sbin}

	cp -a system-cmds/{reboot,nologin} $(BUILD_STAGE)/system-cmds/usr/sbin
	cp -a system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds/usr/bin/pagesize
	chmod a+x $(BUILD_STAGE)/system-cmds/usr/bin/pagesize

	cp -a system-cmds/sync $(BUILD_STAGE)/system-cmds/bin
	cp -a system-cmds/{dmesg,dynamic_pager} $(BUILD_STAGE)/system-cmds/sbin
	$(LN) -s ../usr/sbin/reboot $(BUILD_STAGE)/system-cmds/sbin/halt
	cp -a system-cmds/{arch,getconf,getty,hostinfo,login,passwd} $(BUILD_STAGE)/system-cmds/usr/bin
	cp -a system-cmds/chpass/chpass $(BUILD_STAGE)/system-cmds/usr/bin
	$(LN) -s chpass $(BUILD_STAGE)/system-cmds/usr/bin/chfn
	$(LN) -s chpass $(BUILD_STAGE)/system-cmds/usr/bin/chsh
	cp -a system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds/usr/sbin
	
	mv $(BUILD_BASE)/usr/include/libkern $(BUILD_BASE)/usr/include/libkern.bad
	touch system-cmds/.build_complete
endif

system-cmds-stage: system-cmds
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds
	mkdir -p $(BUILD_DIST)/system-cmds
	
	# system-cmds.mk Prep system-cmds
	cp -a $(BUILD_STAGE)/system-cmds/* $(BUILD_DIST)/system-cmds

	# system-cmds.mk Sign
	$(call SIGN,system-cmds,general.xml)
	
	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_V)
	
	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds system-cmds-stage
