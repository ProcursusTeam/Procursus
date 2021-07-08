ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS      += shell-cmds
SHELL-CMDS_VERSION := 207.40.1
DEB_SHELL-CMDS_V   ?= $(SHELL-CMDS_VERSION)-2

shell-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/shell_cmds/shell_cmds-$(SHELL-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,shell_cmds-$(SHELL-CMDS_VERSION).tar.gz,shell_cmds-$(SHELL-CMDS_VERSION),shell-cmds)

ifneq ($(wildcard $(BUILD_WORK)/shell-cmds/.build_complete),)
shell-cmds:
	@echo "Using previously built shell-cmds."
else
shell-cmds: shell-cmds-setup openpam
	mkdir -p $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX){/bin,/etc/pam.d,$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,8}}}
	-cd $(BUILD_WORK)/shell-cmds; \
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/hexdump hexdump/{conv,display,hexdump,hexsyntax,odsyntax,parse}.c -D'__FBSDID(x)=' -D__DARWIN_C_LEVEL=200112L; \
	cp -a hexdump/hexdump.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su su/su.c -D'__FBSDID(x)=' $(LDFLAGS) -lpam; \
	cp -a su/su.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	cp -a $(BUILD_MISC)/pam/su $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)/etc/pam.d; \
	for bin in killall renice script time which getopt what; do \
		$(CC) $(CFLAGS) -o $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)=' -save-temps; \
		cp -a $$bin/$$bin.1 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 2>/dev/null; \
		cp -a $$bin/$$bin.8 $(BUILD_STAGE)/shell-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8 2>/dev/null; \
	done
	touch $(BUILD_WORK)/shell-cmds/.build_complete
endif

shell-cmds-package: shell-cmds-stage
	# shell-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/shell-cmds

	# shell-cmds.mk Prep shell-cmds
	cp -a $(BUILD_STAGE)/shell-cmds $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/su $(BUILD_DIST)/shell-cmds/$(MEMO_PREFIX)/bin
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
