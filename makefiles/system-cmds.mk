ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS       += system-cmds
SYSTEM-CMDS_VERSION := 854.40.2
PWDARWIN_COMMIT     := 72ae45ce6c025bc2359035cfb941b177149e88ae
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)-13

system-cmds-setup: setup libxcrypt
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/system_cmds/system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz,system_cmds-$(SYSTEM-CMDS_VERSION),system-cmds)
	$(call DO_PATCH,system-cmds,system-cmds,-p1)
	sed -i '/#include <stdio.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	sed -i '1 i\#include\ <libiosexec.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	sed -i -E -e 's|"/usr|"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|"/sbin|"$(MEMO_PREFIX)/sbin|g' \
		$(BUILD_WORK)/system-cmds/shutdown.tproj/pathnames.h
	wget -q -nc -P $(BUILD_SOURCE) \
		https://git.cameronkatri.com/pw-darwin/snapshot/pw-darwin-$(PWDARWIN_COMMIT).tar.zst
	$(call EXTRACT_TAR,pw-darwin-$(PWDARWIN_COMMIT).tar.zst,pw-darwin-$(PWDARWIN_COMMIT),system-cmds/pw-darwin)
	wget -q -nc -P $(BUILD_WORK)/system-cmds/include \
		https://opensource.apple.com/source/launchd/launchd-328/launchd/src/reboot2.h

###
# TODO: Once I implement pam_chauthtok() in pam_unix.so, use PAM for passwd
###

ifneq ($(wildcard $(BUILD_WORK)/system-cmds/.build_complete),)
system-cmds:
	@echo "Using previously built system-cmds."
else
system-cmds: system-cmds-setup libxcrypt openpam libiosexec
	for gperf in $(BUILD_WORK)/system-cmds/getconf.tproj/*.gperf; do \
		LC_ALL=C awk -f $(BUILD_WORK)/system-cmds/getconf.tproj/fake-gperf.awk < $$gperf > $(BUILD_WORK)/system-cmds/getconf.tproj/"$$(basename $$gperf .gperf).c" ; \
	done
	rm -f $(BUILD_WORK)/system-cmds/passwd.tproj/{od,nis}_passwd.c
	cd $(BUILD_WORK)/system-cmds && $(CC) $(CFLAGS) -o passwd passwd.tproj/*.c $(LDFLAGS) -lcrypt # -DINFO_PAM=2 -lpam
	cd $(BUILD_WORK)/system-cmds && $(CC) $(CFLAGS) -o dmesg dmesg.tproj/*.c $(LDFLAGS)
	cd $(BUILD_WORK)/system-cmds && $(CC) $(CFLAGS) -o sysctl sysctl.tproj/sysctl.c $(LDFLAGS)
	cd $(BUILD_WORK)/system-cmds && $(CC) $(CFLAGS) -o arch arch.tproj/*.c $(LDFLAGS) -framework CoreFoundation -framework Foundation -lobjc
	cd $(BUILD_WORK)/system-cmds; \
	for tproj in ac accton dynamic_pager getconf getty hostinfo iostat login mkfile pwd_mkdb reboot shutdown sync vifs vipw zdump zic nologin; do \
		CFLAGS=; \
		EXTRA=; \
		case $$tproj in \
			login) CFLAGS="-DUSE_PAM=1" LDFLAGS="-lpam -liosexec";; \
			dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
			shutdown) LDFLAGS="-lbsm -liosexec";; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) $(CFLAGS) -D__kernel_ptr_semantics="" -I$(BUILD_WORK)/system-cmds/include -o $$tproj $$tproj.tproj/*.c $$EXTRA -D'__FBSDID(x)=' $$CFLAGS $(LDFLAGS) -framework CoreFoundation -framework IOKit $$LDFLAGS; \
	done
	mkdir -p $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX){/etc/pam.d,/bin,/sbin,$(MEMO_SUB_PREFIX)/bin,$(MEMO_SUB_PREFIX)/sbin,$(MEMO_SUB_PREFIX)/share/man/man{1,5,8}}
	install -m755 $(BUILD_WORK)/system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize
	cp -a $(BUILD_WORK)/system-cmds/sync $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{dmesg,dynamic_pager,reboot,nologin,shutdown} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin
	$(LN_S) $(MEMO_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin/halt
ifneq ($(MEMO_SUB_PREFIX),) # compat links because we had faultily installed reboot and nologin to /usr/sbin even though they belong in /sbin
	$(LN_S) $(MEMO_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/reboot
	$(LN_S) $(MEMO_PREFIX)/sbin/nologin $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/nologin
endif
	cp -a $(BUILD_WORK)/system-cmds/{arch,getconf,getty,hostinfo,login,passwd} $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/arch $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/machine
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/{arch,getconf,login,passwd}.tproj/*.1 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	cp -a $(BUILD_WORK)/system-cmds/{getty,nologin,sysctl}.tproj/*.5 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,dmesg,dynamic_pager,getty,hostinfo,iostat,mkfile,nologin,pwd_mkdb,reboot,shutdown,sync,sysctl,vifs,vipw,zdump,zic}.tproj/*.8 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/
	$(LN_S) reboot.8 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/halt.8
	cp -a $(BUILD_MISC)/pam/{login{,.term},passwd} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/etc/pam.d
	+$(MAKE) -C $(BUILD_WORK)/system-cmds/pw-darwin install \
		MEMO_PREFIX="$(MEMO_PREFIX)" \
		MEMO_SUB_PREFIX="$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/system-cmds/"
	$(call AFTER_BUILD)
endif

system-cmds-package: system-cmds-stage
	# system-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/system-cmds

	# system-cmds.mk Prep system-cmds
	cp -a $(BUILD_STAGE)/system-cmds $(BUILD_DIST)

	# system-cmds.mk Sign
	$(call SIGN,system-cmds,general.xml)

	# system-cmds.mk Permissions
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{passwd,login,chpass}
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize

	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_V)

	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds system-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
