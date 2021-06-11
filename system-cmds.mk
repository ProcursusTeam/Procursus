ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS       += system-cmds
SYSTEM-CMDS_VERSION := 854.40.2
PWDARWIN_COMMIT     := 5d48a8af168d8ffb24021d32385d3ecfa699e51d
DEB_SYSTEM-CMDS_V   ?= $(SYSTEM-CMDS_VERSION)-11

system-cmds-setup: setup libxcrypt
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/system_cmds/system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,system_cmds-$(SYSTEM-CMDS_VERSION).tar.gz,system_cmds-$(SYSTEM-CMDS_VERSION),system-cmds)
	$(call DO_PATCH,system-cmds,system-cmds,-p1)
	$(SED) -i '/#include <stdio.h>/a #include <crypt.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
	$(SED) -i '1 i\#include\ <libiosexec.h>' $(BUILD_WORK)/system-cmds/login.tproj/login.c
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
	for tproj in ac accton dynamic_pager getconf getty hostinfo iostat login mkfile pwd_mkdb reboot sync vifs vipw zdump zic nologin; do \
		CFLAGS=; \
		EXTRA=; \
		case $$tproj in \
			login) CFLAGS="-DUSE_PAM=1" LDFLAGS="-lpam -liosexec";; \
			dynamic_pager) CFLAGS="-Idynamic_pager.tproj";; \
			pwd_mkdb) CFLAGS="-D_PW_NAME_LEN=MAXLOGNAME -D_PW_YPTOKEN=\"__YP!\"";; \
		esac ; \
		echo "$$tproj" ; \
		$(CC) $(CFLAGS) -I$(BUILD_WORK)/system-cmds/include -o $$tproj $$tproj.tproj/*.c $$EXTRA -D'__FBSDID(x)=' $$CFLAGS $(LDFLAGS) -framework CoreFoundation -framework IOKit $$LDFLAGS; \
	done
	mkdir -p $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX){/etc/pam.d,/bin,/sbin,$(MEMO_SUB_PREFIX)/bin,$(MEMO_SUB_PREFIX)/sbin,$(MEMO_SUB_PREFIX)/share/man/man{1,5,8}}
	cp -a $(BUILD_WORK)/system-cmds/{reboot,nologin} $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/pagesize.tproj/pagesize.sh $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize
	cp -a $(BUILD_WORK)/system-cmds/sync $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{dmesg,dynamic_pager} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin
ifneq ($(MEMO_SUB_PREFIX),)
	$(LN) -sf $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/reboot $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/sbin/halt
endif
	cp -a $(BUILD_WORK)/system-cmds/{arch,getconf,getty,hostinfo,login,passwd} $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,iostat,mkfile,pwd_mkdb,sysctl,vifs,vipw,zdump,zic} $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_WORK)/system-cmds/{arch,getconf,login,passwd}.tproj/*.1 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	cp -a $(BUILD_WORK)/system-cmds/{getty,nologin,sysctl}.tproj/*.5 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/
	cp -a $(BUILD_WORK)/system-cmds/{ac,accton,dmesg,dynamic_pager,getty,hostinfo,iostat,mkfile,nologin,pwd_mkdb,reboot,sync,sysctl,vifs,vipw,zdump,zic}.tproj/*.8 $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/
	$(LN) -sf reboot.8.zst $(BUILD_STAGE)/system-cmds$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/halt.8.zst
	cp -a $(BUILD_MISC)/pam/{login{,.term},passwd} $(BUILD_STAGE)/system-cmds/$(MEMO_PREFIX)/etc/pam.d
	+$(MAKE) -C $(BUILD_WORK)/system-cmds/pw-darwin install \
		DESTDIR="$(BUILD_STAGE)/system-cmds/"
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
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{passwd,login}
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/system-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pagesize

	# system-cmds.mk Make .debs
	$(call PACK,system-cmds,DEB_SYSTEM-CMDS_V)

	# system-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/system-cmds

.PHONY: system-cmds system-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
