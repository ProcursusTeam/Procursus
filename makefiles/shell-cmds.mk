ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS      += shell-cmds
SHELL-CMDS_VERSION := 309
DEB_SHELL-CMDS_V   ?= $(SHELL-CMDS_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && echo 1),1)
SHELL-CMDS_SBUF_LIBS = -lsbuf
else
SHELL-CMDS_SBUF_LIBS = $(BUILD_WORK)/shell-cmds/usbuf.o
endif

shell-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,shell_cmds,$(SHELL-CMDS_VERSION),shell_cmds-$(SHELL-CMDS_VERSION))
	$(call EXTRACT_TAR,shell_cmds-$(SHELL-CMDS_VERSION).tar.gz,shell_cmds-shell_cmds-$(SHELL-CMDS_VERSION),shell-cmds)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/shell-cmds,https://github.com/alexreg/libsbuf/raw/master/src/{sbuf.c$(comma)sbuf.h$(comma)debug.h});
	sed -i 's|"/bin:/usr/bin|"/bin:/usr/bin:$(MEMO_PREFIX)/bin:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin|g' $(BUILD_WORK)/shell-cmds/su/su.c
	sed -i -e 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|"/etc|"$(MEMO_PREFIX)/etc|g' $(BUILD_WORK)/shell-cmds/{path_helper/path_helper.c,apply/apply.1,renice/renice.8}
	sed -i -e '/rootless\.h/d' -e '/SoftLinking\/SoftLinking\.h/d' $(BUILD_WORK)/shell-cmds/su/su.c
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 2000 ] && echo 1),1)
	sed 's/sbuf/usbuf/g' < $(BUILD_WORK)/shell-cmds/sbuf.c > $(BUILD_WORK)/shell-cmds/__usbuf.c
	sed 's/sbuf/usbuf/g' < $(BUILD_WORK)/shell-cmds/sbuf.h > $(BUILD_WORK)/shell-cmds/__usbuf.h
	sed -i 's/"usbuf\.h"/"__usbuf\.h"/g' $(BUILD_WORK)/shell-cmds/__usbuf.c
endif

ifneq ($(wildcard $(BUILD_WORK)/shell-cmds/.build_complete),)
shell-cmds:
	@echo "Using previously built shell-cmds."
else
shell-cmds: shell-cmds-setup openpam libxo
	mkdir -p $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX){/bin,/etc/pam.d,$(MEMO_SUB_PREFIX)/{bin,libexec,share/man/man{1,8}}}
ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 2000 ] && echo 1),1)
	$(CC) $(CFLAGS) -c $(BUILD_WORK)/shell-cmds/__usbuf.c -o $(BUILD_WORK)/shell-cmds/usbuf.o
endif
	-cd $(BUILD_WORK)/shell-cmds; \
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/hexdump hexdump/{conv,display,hexdump,hexsyntax,odsyntax,parse}.c -D'__FBSDID(x)=' -D__DARWIN_C_LEVEL=200112L; \
	cp -a hexdump/hexdump.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su su/su.c -D'__FBSDID(x)=' -D'SOFT_LINK_DYLIB(x)=' -D'SOFT_LINK_FUNCTION(...)=' -D'rootless_restricted_environment()=0' -D'soft_ess_notify_su(...)=0' -D'islibEndpointSecuritySystemess_notify_suAvailable()=0' $(LDFLAGS) -lpam; \
	cp -a su/su.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	cp -a $(BUILD_MISC)/pam/su $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)/etc/pam.d; \
	for bin in killall renice script time which getopt what jot apply lastcomm systime shlock systime w whereis; do \
		echo $$bin; \
		if [ "$$bin" = "w" ]; then LDFLAGS="$(LDFLAGS) $(SHELL-CMDS_SBUF_LIBS) -lxo -lutil"; \
		elif [ "$$bin" = "apply" ]; then LDFLAGS="$(LDFLAGS) $(SHELL-CMDS_SBUF_LIBS)"; \
		else LDFLAGS="$(LDFLAGS)"; fi; \
		$(CC) $(CFLAGS) $$LDFLAGS -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -DHAVE_UTMPX=1 -save-temps; \
		cp -a $$bin/$$bin.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 2>/dev/null; \
		cp -a $$bin/$$bin.8 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8 2>/dev/null; \
	done; \
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/path_helper path_helper/path_helper.c -save-temps; \
	cp -a path_helper/path_helper.8 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8;
	$(call AFTER_BUILD)
endif

shell-cmds-package: shell-cmds-stage
	# shell-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/shell-cmds

	# shell-cmds.mk Prep shell-cmds
	cp -a $(BUILD_STAGE)/shell-cmds $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su $(BUILD_DIST)/shell-cmds/$(MEMO_PREFIX)/bin
endif

	# shell-cmds.mk Sign
	$(call SIGN,shell-cmds,general.xml)
	$(LDID) -S$(BUILD_MISC)/entitlements/pam.xml $(BUILD_DIST)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su
	find $(BUILD_DIST)/shell-cmds -name '.ldid*' -type f -delete

	# shell-cmds.mk Permissions
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(FAKEROOT) chmod u+s $(BUILD_DIST)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su
endif

	# shell-cmds.mk Make .debs
	$(call PACK,shell-cmds,DEB_SHELL-CMDS_V)

	# shell-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/shell-cmds

.PHONY: shell-cmds shell-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
