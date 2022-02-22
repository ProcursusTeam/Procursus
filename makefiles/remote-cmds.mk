ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += remote-cmds
REMOTE-CMDS_VERSION := 64
LIBTELNET_VERSION   := 13
DEB_REMOTE-CMDS_V   ?= $(REMOTE-CMDS_VERSION)

ifeq (,$(finstring darwin,$(MEMO_TARGET)))
REMOTE_CMDS_BINS    := logger talk talkd telnet telnetd tftp tftpd wall
else
REMOTE_CMDS_BINS    := telnet telnetd
endif

remote-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,remote_cmds,$(REMOTE-CMDS_VERSION),remote_cmds-$(REMOTE-CMDS_VERSION))
	$(call GITHUB_ARCHIVE,apple-oss-distributions,libtelnet,$(LIBTELNET_VERSION),remote_cmds-$(LIBTELNET_VERSION))
	$(call EXTRACT_TAR,remote_cmds-$(REMOTE-CMDS_VERSION).tar.gz,remote_cmds-remote_cmds-$(REMOTE-CMDS_VERSION),remote-cmds)
	$(call EXTRACT_TAR,libtelnet-$(LIBTELNET_VERSION).tar.gz,libtelnet-libtelnet-$(LIBTELNET_VERSION),remote-cmds/libtelnet)
	mkdir -p $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	sed -i -e 's/line\[/weneta\[/g' -e 's/line,/weneta,/g'  $(BUILD_WORK)/remote-cmds/telnetd.tproj/sys_term.c
	sed -i -e '86d' $(BUILD_WORK)/remote-cmds/telnetd.tproj/authenc.c
	# not mentioned in xcode project
	rm -f $(BUILD_WORK)/remote-cmds/libtelnet/pk.{c,h}
ifneq ($(wildcard $(BUILD_WORK)/remote-cmds/.build_complete),)
remote-cmds:
	@echo "Using previously built remote-cmds."
else
remote-cmds: remote-cmds-setup ncurses
	mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libtelnet
	mkdir -p $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,8}/}
	cd $(BUILD_WORK)/remote-cmds/libtelnet; \
	$(CC) $(CFLAGS) -c *.c -D'__FBSDID=__RCSID' -I. -DHAS_CGETENT -DAUTHENTICATION -DRSA -DFORWARD -DHAVE_STDLIB_H; \
	$(AR) -cr $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtelnet.a *.o; \
	install -Dm644 *.h $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libtelnet
	cd $(BUILD_WORK)/remote-cmds; \
	talk=-lncurses; \
	talkd=ttymsg.o; \
	telnet="-DUSE_TERMIO -lncursesw -ltelnet"; \
	telnetd="-DTIOCEXT -DNO_UTMP -DLINEMODE -DKLUDGELINEMODE -DUSE_TERMIO -DOLD_ENVIRON -DENV_HACK -DINET6 -D_PATH_WTMP -ltelnet -lncursesw"; \
	tftp=-ledit; \
	$(CC) $(CFLAGS) -c wall.tproj/ttymsg.c; \
	for bin in $(REMOTE_CMDS_BINS); do \
		echo $$bin; \
		$(CC) -Iinclude $${!bin} $$CFLAGS $(LDFLAGS) -o $$bin $$bin.tproj/*.c; \
		[ -f $$bin.tproj/$$bin.1 ] && $(INSTALL) -Dm644 $$bin.tproj/$$bin.1 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/  || true; \
		[ -f $$bin.tproj/$$bin.8 ] && $(INSTALL) -Dm644 $$bin.tproj/$$bin.8 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/ || true; \
	done;
	install -m755 $(BUILD_WORK)/remote-cmds/telnetd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec;
	install -m755 $(BUILD_WORK)/remote-cmds/telnet $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	install -m755 $(BUILD_WORK)/remote-cmds/tftpd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
	install -m755 $(BUILD_WORK)/remote-cmds/talkd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ntalkd;
	install -m755 $(BUILD_WORK)/remote-cmds/{logger,wall,talk,tftp} $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin;
endif
	$(call AFTER_BUILD)
endif

remote-cmds-package: remote-cmds-stage
	# remote-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/remote-cmds

	# remote-cmds.mk Prep remote-cmds
	cp -a $(BUILD_STAGE)/remote-cmds $(BUILD_DIST)

	# remote-cmds.mk Sign
	$(call SIGN,remote-cmds,general.xml)

	# remote-cmds.mk Make .debs
	$(call PACK,remote-cmds,DEB_REMOTE-CMDS_V)

	# remote-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/remote-cmds

.PHONY: remote-cmds remote-cmds-package
