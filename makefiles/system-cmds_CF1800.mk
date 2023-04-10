ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SYSTEM-CMDS_CF1800_VERSION := 950
DEB_SYSTEM-CMDS_CF1800_V   ?= $(SYSTEM-CMDS_CF1800_VERSION)-1
PWDARWIN_CF1800_COMMIT     := 72ae45ce6c025bc2359035cfb941b177149e88ae

system-cmds_CF1800-setup: setup libxcrypt
	$(call GITHUB_ARCHIVE,apple-oss-distributions,system_cmds,$(SYSTEM-CMDS_CF1800_VERSION),system_cmds-$(SYSTEM-CMDS_CF1800_VERSION))
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_CF1800_VERSION).tar.gz,system_cmds-system_cmds-$(SYSTEM-CMDS_CF1800_VERSION),system-cmds)
	$(call DO_PATCH,system-cmds-ios15,system-cmds,-p1)
	sed -i '/#include <stdio.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	sed -i '1 i\#include\ <libiosexec.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	sed -i '1 i\#define IOPOL_TYPE_VFS_HFS_CASE_SENSITIVITY 1\n#define IOPOL_SCOPE_PROCESS 0\n#define IOPOL_VFS_HFS_CASE_SENSITIVITY_DEFAULT 0\n#define IOPOL_VFS_HFS_CASE_SENSITIVITY_FORCE_CASE_SENSITIVE 1\n#define PRIO_DARWIN_ROLE_UI 0x2' $(BUILD_WORK)/system-cmds/taskpolicy.tproj/taskpolicy.c
	sed -i -E -e 's|"/usr|"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|"/sbin|"$(MEMO_PREFIX)/sbin|g' \
		$(BUILD_WORK)/system-cmds/{shutdown.tproj/pathnames.h,getty.tproj/{ttys,gettytab}.5,sc_usage.tproj/sc_usage.{1,c},at.tproj/{at.1,pathnames.h}}
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://git.cameronkatri.com/pw-darwin/snapshot/pw-darwin-$(PWDARWIN_CF1800_COMMIT).tar.zst)
	$(call EXTRACT_TAR,pw-darwin-$(PWDARWIN_CF1800_COMMIT).tar.zst,pw-darwin-$(PWDARWIN_CF1800_COMMIT),system-cmds/pw-darwin)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/system-cmds/include, \
		https://github.com/apple-oss-distributions/launchd/raw/launchd-328/launchd/src/reboot2.h)
	sed -i 's|"/etc|"$(MEMO_PREFIX)/etc|' $(BUILD_WORK)/system-cmds/passwd.tproj/{file_,}passwd.c
	sed -i 's|#include <mach/i386/vm_param.h>|#include <mach/vm_param.h>|' $(BUILD_WORK)/system-cmds/memory_pressure.tproj/memory_pressure.c
	# Allow placing kernels from [redacted] sources on rootless
	sed -i 's|/System/Library/Kernels/kernel.development|$(MEMO_PREFIX)/Library/Kernels/kernel.development|' $(BUILD_WORK)/system-cmds/latency.tproj/latency.{1,c}
	sed -i 's/plonk(sc_token);/plonk(sc_tokid);/g' $(BUILD_WORK)/system-cmds/at.tproj/parsetime.c

###
# TODO: Once I implement pam_chauthtok() in pam_unix.so, use PAM for passwd
###

ifneq ($(wildcard $(BUILD_WORK)/system-cmds/.build_complete),)
system-cmds_CF1800:
	@echo "Using previously built system-cmds."
else
system-cmds_CF1800: system-cmds-setup libxcrypt openpam libiosexec ncurses
	for gperf in $(BUILD_WORK)/system-cmds/getconf.tproj/*.gperf; do \
		LC_ALL=C awk -f $(BUILD_WORK)/system-cmds/getconf.tproj/fake-gperf.awk < $$gperf > $(BUILD_WORK)/system-cmds/getconf.tproj/"$$(basename $$gperf .gperf).c" ; \
	done
	rm -f $(BUILD_WORK)/system-cmds/passwd.tproj/{od,nis}_passwd.c
	cd $(BUILD_WORK)/system-cmds && $(CC) $(CFLAGS) $(LDFLAGS) -o wait4path.x wait4path/*.c
	cd $(BUILD_WORK)/system-cmds; \
	for tproj in ac accton arch at atrun cpuctl dmesg dynamic_pager fs_usage getconf getty hostinfo iostat latency login lskq memory_pressure mkfile newgrp purge pwd_mkdb reboot shutdown stackshot trace passwd sync sysctl vifs vipw zdump zic nologin taskpolicy lsmp sc_usage ltop; do \
		CFLAGS=; \
		case $$tproj in \
			arch) LDFLAGS="-framework CoreFoundation -framework Foundation -lobjc";; \
			login) CFLAGS="-DUSE_PAM=1" LDFLAGS="-lpam -liosexec";; \
			dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
			passwd) LDFLAGS="-lcrypt";; \
			shutdown) LDFLAGS="-lbsm -liosexec";; \
			sc_usage) LDFLAGS="-lncurses";; \
			at) LDFLAGS="-Iat.tproj -DPERM_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cron\" -DDAEMON_UID=1 -DDAEMON_GID=1 -D__FreeBSD__ -DDEFAULT_AT_QUEUE='a' -DDEFAULT_BATCH_QUEUE='b'";; \
			fs_usage) LDFLAGS="-Wno-error-implicit-function-declaration $(BUILD_MISC)/PrivateFrameworks/ktrace.framework/ktrace.tbd";; \
			latency) LDFLAGS="-lncurses -lutil";; \
			trace) LDFLAGS="-lutil";; \
			lskq) LDFLAGS="-Ilskq.tproj -DEVFILT_NW_CHANNEL=(-16)";; \
			zic) CFLAGS='-DUNIDEF_MOVE_LOCALTIME -DTZDIR="/var/db/timezone/zoneinfo" -DTZDEFAULT="/var/db/timezone/localtime"';; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) $(CFLAGS) -D__kernel_ptr_semantics="" -I$(BUILD_WORK)/system-cmds/include -o $$tproj $$tproj.tproj/*.c -D'__FBSDID(x)=' $${CFLAGS} $(LDFLAGS) -framework CoreFoundation -framework IOKit $${LDFLAGS} -DPRIVATE -D__APPLE_PRIVATE ; \
	done
	mkdir -p $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX){/Library/LaunchDaemons,/etc/pam.d,/bin,/sbin,$(MEMO_SUB_PREFIX)/bin,$(MEMO_SUB_PREFIX)/{sbin,libexec,share/man/man{1,5,8}}}
	sed 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|' < $(BUILD_WORK)/system-cmds/atrun.tproj/com.apple.atrun.plist > $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.atrun.plist
	install -m755 $(BUILD_WORK)/system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize
	install -m755 $(BUILD_WORK)/system-cmds/wait4path.x $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin/wait4path
	cp -a $(BUILD_WORK)/system-cmds/{dmesg,dynamic_pager,nologin,reboot,shutdown} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/sync $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,taskpolicy,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/{arch,at,cpuctl,fs_usage,getconf,hostinfo,latency,login,lskq,lsmp,ltop,memory_pressure,newgrp,passwd,purge,sc_usage,stackshot,trace} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{atrun,getty} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_WORK)/system-cmds/{{arch,at,fs_usage,getconf,latency,login,lskq,lsmp,ltop,memory_pressure,newgrp,pagesize,passwd,trace,vm_stat,zprint}.tproj,wait4path}/*.1 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_WORK)/system-cmds/{getty,nologin,sysctl}.tproj/*.5 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,atrun,cpuctl,dmesg,dynamic_pager,getty,hostinfo,iostat,mkfile,nologin,nvram,purge,pwd_mkdb,reboot,sa,shutdown,sync,sysctl,taskpolicy,vifs,vipw,zdump,zic}.tproj/*.8 $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
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

system-cmds_CF1800-package: system-cmds-stage
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds

	# system-cmds.mk Prep system-cmds
	cp -a $(BUILD_STAGE)/system-cmds $(BUILD_DIST)

	# system-cmds.mk Sign
	$(call SIGN,system-cmds,general.xml)
	$(LDID) -S$(BUILD_MISC)/entitlements/lsmp.xml $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsmp
	$(LDID) -S$(BUILD_MISC)/entitlements/taskpolicy.xml $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/taskpolicy
	$(LDID) -S$(BUILD_MISC)/entitlements/dynamic_pager.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)/sbin/dynamic_pager
	$(LDID) -S$(BUILD_MISC)/entitlements/fs_usage.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fs_usage
	$(LDID) -S$(BUILD_MISC)/entitlements/login.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/login
	$(LDID) -S$(BUILD_MISC)/entitlements/passwd.plist $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/passwd

	find $(BUILD_DIST)/system-cmds -name '.ldid*' -type f -delete

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{passwd,login,chpass}
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize

	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_CF1800_V)

	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds_CF1800 system-cmds_CF1800-package

endif # ($(MEMO_TARGET),darwin-\*)
