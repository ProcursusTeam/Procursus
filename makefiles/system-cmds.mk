ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS       += system-cmds
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
SYSTEM-CMDS_VERSION := 854.40.2
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)-15
else ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
SYSTEM-CMDS_VERSION := 880.60.2
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)-1
else
SYSTEM-CMDS_VERSION := 970.0.4
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)
endif
PWDARWIN_COMMIT     := 72ae45ce6c025bc2359035cfb941b177149e88ae

system-cmds-setup: setup libxcrypt
	$(call GITHUB_ARCHIVE,apple-oss-distributions,system_cmds,$(SYSTEM-CMDS_VERSION),system_cmds-$(SYSTEM-CMDS_VERSION))
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1700 ] && echo 1),1)
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz,system_cmds-system_cmds-$(SYSTEM-CMDS_VERSION),system-cmds)
else
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz,system_cmds-system_cmds-$(SYSTEM-CMDS_VERSION),system-cmds)
endif
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1800 ] && echo 1),1)
	$(call DO_PATCH,system-cmds,system-cmds,-p1)
	for tproj in $(BUILD_WORK)/system-cmds/*.tproj; do \
		$(LN_S) $$(basename $$tproj) $(BUILD_WORK)/system-cmds/$$(basename $$tproj .tproj); \
	done
else
	$(call DO_PATCH,system-cmds-ios15,system-cmds,-p1)
endif
	sed -i '/#include <stdio.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/login/login.c
	sed -i -E -e 's|"/usr|"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|"/sbin|"$(MEMO_PREFIX)/sbin|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' \
		$(BUILD_WORK)/system-cmds/{{shutdown,getty}/pathnames.h,getty/{ttys,gettytab}.5,sc_usage/sc_usage.{1,c},at/{at.1,pathnames.h},passwd/{{file_,}passwd.c,passwd.1},pwd_mkdb/pwd_mkdb.8,sysctl/sysctl.conf.5,chpass/chpass.1,latency/latency.{1,c},arch/arch.c,atrun/atrun.8,vipw/vipw.8,login/login.1}
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://git.cameronkatri.com/pw-darwin/snapshot/pw-darwin-$(PWDARWIN_COMMIT).tar.zst)
	$(call EXTRACT_TAR,pw-darwin-$(PWDARWIN_COMMIT).tar.zst,pw-darwin-$(PWDARWIN_COMMIT),system-cmds/pw-darwin)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/system-cmds/include, \
		https://github.com/apple-oss-distributions/launchd/raw/launchd-328/launchd/src/reboot2.h)
	sed -i 's|#include <mach/i386/vm_param.h>|#include <mach/vm_param.h>|' $(BUILD_WORK)/system-cmds/memory_pressure/memory_pressure.c
	# Allow placing kernels from [redacted] sources on rootless
	sed -i 's|/System/Library/Kernels/kernel.development|$(MEMO_PREFIX)/Library/Kernels/kernel.development|' $(BUILD_WORK)/system-cmds/latency/latency.{1,c}
	mkdir -p $(BUILD_WORK)/system-cmds/bin

ifneq ($(wildcard $(BUILD_WORK)/system-cmds/.build_complete),)
system-cmds:
	@echo "Using previously built system-cmds."
else
system-cmds: system-cmds-setup libxcrypt openpam libiosexec ncurses
	for gperf in $(BUILD_WORK)/system-cmds/getconf/*.gperf; do \
		LC_ALL=C awk -f $(BUILD_WORK)/system-cmds/getconf/fake-gperf.awk < $$gperf > $(BUILD_WORK)/system-cmds/getconf/"$$(basename $$gperf .gperf).c" ; \
	done
	rm -f $(BUILD_WORK)/system-cmds/passwd/{od,nis}_passwd.c;
	set -e; \
	cd $(BUILD_WORK)/system-cmds; \
	for bin in ac accton arch at atrun cpuctl dmesg dynamic_pager fs_usage getconf getty hostinfo iostat latency login lskq memory_pressure mkfile newgrp purge pwd_mkdb reboot shutdown stackshot passwd sync sysctl vifs vipw zdump zic nologin taskpolicy wait4path lsmp sc_usage ltop; do \
		CFLAGS=; \
		case $$bin in \
			arch) LDFLAGS="-framework CoreFoundation -framework Foundation -lobjc";; \
			login) CFLAGS="-DUSE_PAM=1" LDFLAGS="-lpam -liosexec";; \
			dynamic_pager) CFLAGS="-Idynamic_pager";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
			passwd) CFLAGS="-DINFO_PAM=4" LDFLAGS="-lcrypt -lpam";; \
			shutdown) LDFLAGS="-lbsm -liosexec";; \
			sc_usage) LDFLAGS="-lncurses";; \
			taskpolicy) CFLAGS="-DIOPOL_TYPE_VFS_HFS_CASE_SENSITIVITY=1 -DIOPOL_SCOPE_PROCESS=0 -DIOPOL_VFS_HFS_CASE_SENSITIVITY_DEFAULT=0 -DIOPOL_VFS_HFS_CASE_SENSITIVITY_FORCE_CASE_SENSITIVE=1 -DPRIO_DARWIN_ROLE_UI=2";; \
			at) LDFLAGS="-Iat -DPERM_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cron\" -DDAEMON_UID=1 -DDAEMON_GID=1 -D__FreeBSD__ -DDEFAULT_AT_QUEUE='a' -DDEFAULT_BATCH_QUEUE='b'";; \
			fs_usage) LDFLAGS="-Wno-error-implicit-function-declaration $(BUILD_MISC)/PrivateFrameworks/ktrace.framework/ktrace.tbd";; \
			latency) LDFLAGS="-lncurses -lutil";; \
			lskq) LDFLAGS="-Ilskq -DEVFILT_NW_CHANNEL=(-16)";; \
			zic) CFLAGS='-DUNIDEF_MOVE_LOCALTIME -DTZDIR="/var/db/timezone/zoneinfo" -DTZDEFAULT="/var/db/timezone/localtime"';; \
			zdump) CFLAGS='-Izic';; \
		esac ; \
		echo "$$bin" ; \
		$(CC) $(CFLAGS) -D__kernel_ptr_semantics="" -I$(BUILD_WORK)/system-cmds/include -o bin/$$bin $$bin/*.c -D'__FBSDID(x)=' $${CFLAGS} $(LDFLAGS) -framework CoreFoundation -framework IOKit $${LDFLAGS} -DPRIVATE -D__APPLE_PRIVATE ; \
	done
	mkdir -p $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX){/Library/LaunchDaemons,/etc/pam.d,/bin,/sbin,$(MEMO_SUB_PREFIX)/bin,$(MEMO_SUB_PREFIX)/{sbin,libexec,share/man/man{1,5,8}}}
	sed 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|' < $(BUILD_WORK)/system-cmds/atrun/com.apple.atrun.plist > $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.atrun.plist
	install -m755 $(BUILD_WORK)/system-cmds/pagesize/pagesize.sh $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize
	cp -a $(BUILD_WORK)/system-cmds/bin/{dmesg,dynamic_pager,nologin,reboot,shutdown} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/bin/sync $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/bin/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,taskpolicy,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/bin/{arch,at,cpuctl,fs_usage,getconf,hostinfo,latency,login,lskq,lsmp,memory_pressure,newgrp,passwd,purge,sc_usage,stackshot,wait4path} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 2000 ] && echo 1),1)
	cp -a $(BUILD_WORK)/system-cmds/bin/ltop $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
endif
	cp -a $(BUILD_WORK)/system-cmds/bin/{atrun,getty} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_WORK)/system-cmds/{{arch,at,fs_usage,getconf,latency,login,lskq,lsmp,ltop,memory_pressure,newgrp,pagesize,passwd,vm_stat,zprint},wait4path}/*.1 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_WORK)/system-cmds/{getty,nologin,sysctl}/*.5 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,atrun,cpuctl,dmesg,dynamic_pager,getty,hostinfo,iostat,mkfile,nologin,nvram,purge,pwd_mkdb,reboot,sa,shutdown,sync,sysctl,taskpolicy,vifs,vipw,zdump,zic}/*.8 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(LN_SR) $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{arch,machine}
	$(LN_S) $(MEMO_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin/halt
ifneq ($(MEMO_SUB_PREFIX),) # compat links because we had faultily installed reboot and nologin to /usr/sbin even though they belong in /sbin
	$(LN_S) $(MEMO_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/reboot
	$(LN_S) $(MEMO_PREFIX)/sbin/nologin $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/nologin
endif
	$(LN_S) reboot.8 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/halt.8
	cp -a $(BUILD_MISC)/pam/{login{,.term},passwd} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/etc/pam.d
	+$(MAKE) -C $(BUILD_WORK)/system-cmds/pw-darwin install \
		MEMO_PREFIX="$(MEMO_PREFIX)" \
		MEMO_SUB_PREFIX="$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/system-cmds/"
	chmod 4755 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chpass # AFTER_BUILD needs this
	$(call AFTER_BUILD)
endif

system-cmds-package: system-cmds-stage
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds

	# system-cmds.mk Prep system-cmds
	cp -a $(BUILD_STAGE)/system-cmds $(BUILD_DIST)

	# system-cmds.mk Sign
	$(call SIGN,system-cmds,general.xml)
ifeq ($(shell [ $(CFVER_WHOLE) -lt 1800 ] && echo 1),1)
	$(LDID) -S$(BUILD_MISC)/entitlements/lsmp-legacy.xml $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsmp
else
	$(LDID) -S$(BUILD_MISC)/entitlements/lsmp.xml $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsmp
endif
	$(LDID) -S$(BUILD_MISC)/entitlements/taskpolicy.xml $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/taskpolicy
	$(LDID) -S$(BUILD_MISC)/entitlements/dynamic_pager.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)/sbin/dynamic_pager
	$(LDID) -S$(BUILD_MISC)/entitlements/fs_usage.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fs_usage
	$(LDID) -S$(BUILD_MISC)/entitlements/login.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/login
	$(LDID) -S$(BUILD_MISC)/entitlements/passwd.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/passwd

	find $(BUILD_DIST)/system-cmds -name '.ldid*' -type f -delete

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{passwd,login,chpass,newgrp}
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize

	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_V)

	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds system-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
