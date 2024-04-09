ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += remote-cmds
REMOTE-CMDS_VERSION := 302
LIBTELNET_VERSION   := 13
DEB_REMOTE-CMDS_V   ?= $(REMOTE-CMDS_VERSION)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
REMOTE-CMDS_BINS    := telnet telnetd
else
REMOTE-CMDS_BINS    := logger talk telnet telnetd tftp tftpd wall
endif

remote-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,remote_cmds,$(REMOTE-CMDS_VERSION),remote_cmds-$(REMOTE-CMDS_VERSION))
	$(call GITHUB_ARCHIVE,apple-oss-distributions,libtelnet,$(LIBTELNET_VERSION),libtelnet-$(LIBTELNET_VERSION))
	$(call EXTRACT_TAR,remote_cmds-$(REMOTE-CMDS_VERSION).tar.gz,remote_cmds-remote_cmds-$(REMOTE-CMDS_VERSION),remote-cmds)
	$(call EXTRACT_TAR,libtelnet-$(LIBTELNET_VERSION).tar.gz,libtelnet-libtelnet-$(LIBTELNET_VERSION),remote-cmds/libtelnet)
	mkdir -p $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/{private/tftpboot,Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{bin,libexec,share/man/man{1,8}}}
	sed -i 's/TARGET_OS_OSX/1/g' $(BUILD_WORK)/remote-cmds/telnetd/sys_term.c
	sed -i 's/setupterm(char/setupFOOterm(char/g' $(BUILD_WORK)/remote-cmds/telnet/telnet.c
	rm -f $(BUILD_WORK)/remote-cmds/{telnetd/{strlcpy,authenc}.c,libtelnet/pk.{c,h}}

ifneq ($(wildcard $(BUILD_WORK)/remote-cmds/.build_complete),)
remote-cmds:
	@echo "Using previously built remote-cmds."
else
remote-cmds: remote-cmds-setup ncurses libedit
	mkdir -p $(BUILD_WORK)/remote-cmds/include/libtelnet
	cd $(BUILD_WORK)/remote-cmds/libtelnet; \
		$(CC) $(CFLAGS) -c *.c -D'__FBSDID=__RCSID' -I. -DHAS_CGETENT -DAUTHENTICATION -DRSA -DFORWARD -DHAVE_STDLIB_H; \
		cp -a *.h $(BUILD_WORK)/remote-cmds/include/libtelnet; \
		$(AR) -cr $(BUILD_WORK)/remote-cmds/libtelnet.a *.o;
	cd $(BUILD_WORK)/remote-cmds; \
	talk=-lncurses; \
	telnet="-DTERMCAP -DKLUDGELINEMODE -DUSE_TERMIO -DENV_HACK -DAUTHENTICATION -DSKEY -DIPSEC -DINET6 -DFORWARD -lncursesw -lipsec $(BUILD_WORK)/remote-cmds/libtelnet.a"; \
	telnetd="-DDIAGNOSTICS -DNO_UTMP -DLINEMODE -DKLUDGELINEMODE -DUSE_TERMIO -DOLD_ENVIRON -DENV_HACK -DINET6 -D_PATH_WTMP $(BUILD_WORK)/remote-cmds/libtelnet.a -lncursesw"; \
	tftp="-ledit $(BUILD_WORK)/remote-cmds/tftpd/tftp-"*.c; \
	$(CC) $(CFLAGS) -c wall/ttymsg.c; \
	for bin in $(REMOTE-CMDS_BINS); do \
		echo $$bin; \
		$(CC) -I$(BUILD_WORK)/remote-cmds/tftpd -Iinclude $${!bin} $$CFLAGS $(LDFLAGS) -o $$bin/$$bin $$bin/*.c; \
		[ -f $$bin/$$bin.1 ] && $(INSTALL) -Dm644 $$bin/$$bin.1 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/  || true; \
		[ -f $$bin/$$bin.8 ] && $(INSTALL) -Dm644 $$bin/$$bin.8 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/ || true; \
	done;
	install -m755 $(BUILD_WORK)/remote-cmds/telnetd/telnetd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec;
	install -m755 $(BUILD_WORK)/remote-cmds/telnet/telnet $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -e 's|@LOGIN_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|@MEMO_PREFIX@@MEMO_SUB_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/remote-cmds/com.apple.telnetd.plist > $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.telnetd.plist;
	sed -e 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|/private/tftpboot|$(MEMO_PREFIX)/private/tftpboot|g' $(BUILD_WORK)/remote-cmds/tftpd/tftp.plist > $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.tftpd.plist;
	install -m755 $(BUILD_WORK)/remote-cmds/tftpd/tftpd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec;
	install -m755 $(BUILD_WORK)/remote-cmds/logger/logger $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
	install -m755 $(BUILD_WORK)/remote-cmds/wall/wall $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
	install -m755 $(BUILD_WORK)/remote-cmds/talk/talk $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec;
	install -m755 $(BUILD_WORK)/remote-cmds/tftp/tftp $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
else
	sed -e 's|@LOGIN_PREFIX@|/usr|g' -e 's|@MEMO_PREFIX@@MEMO_SUB_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_MISC)/remote-cmds/com.apple.telnetd.plist > $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons/com.apple.telnetd.plist;
endif
	$(call AFTER_BUILD)
endif

remote-cmds-package: remote-cmds-stage
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	# remote-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/remote-cmds

	# remote-cmds.mk Prep remote-cmds
	cp -a $(BUILD_STAGE)/remote-cmds $(BUILD_DIST)

	# remote-cmds.mk Sign
	$(call SIGN,remote-cmds,general.xml)
	$(LDID) -S$(BUILD_MISC)/entitlements/network-server.xml $(BUILD_DIST)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/telnetd

	# remote-cmds.mk Make .debs
	$(call PACK,remote-cmds,DEB_REMOTE-CMDS_V)

	# remote-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/remote-cmds
else
	# remote-cmds.mk Package structure
	rm -rf $(BUILD_DIST)/telnet{,d}
	mkdir -p $(BUILD_DIST)/telnet{,d}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# remote-cmds.mk Prep telnet
	cp -a $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/telnet/$(MEMO_PREFIX)$(MEMO_SUB_PRRFIX)
	cp -a $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/telnet/$(MEMO_PREFIX)$(MEMO_SUB_PRRFIX)/share/man

	# remote-cmds.mk Prep telnetd
	cp -a $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec $(BUILD_DIST)/telnetd/$(MEMO_PREFIX)$(MEMO_SUB_PRRFIX)
	cp -a $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library $(BUILD_DIST)/telnetd/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8 $(BUILD_DIST)/telnetd/$(MEMO_PREFIX)$(MEMO_SUB_PRRFIX)/share/man

	# remote-cmds.mk Sign
	$(call SIGN,telnet,general.xml)
	$(call SIGN,telnetd,network-server.xml)

	# remote-cmds.mk Make .debs
	$(call PACK,telnet,DEB_REMOTE-CMDS_V)
	$(call PACK,telnetd,DEB_REMOTE-CMDS_V)

	# remote-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/telnet{,d}
endif

.PHONY: remote-cmds remote-cmds-package
