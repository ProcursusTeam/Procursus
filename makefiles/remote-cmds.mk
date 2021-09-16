ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += remote-cmds
REMOTE-CMDS_VERSION := 63
LIBTELNET_VERSION   := 13
DEB_REMOTE-CMDS_V   ?= $(REMOTE-CMDS_VERSION)

remote-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/remote_cmds/remote_cmds-$(REMOTE-CMDS_VERSION).tar.gz
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/libtelnet/libtelnet-$(LIBTELNET_VERSION).tar.gz
	$(call EXTRACT_TAR,remote_cmds-$(REMOTE-CMDS_VERSION).tar.gz,remote_cmds-$(REMOTE-CMDS_VERSION),remote-cmds)
	$(call EXTRACT_TAR,libtelnet-$(LIBTELNET_VERSION).tar.gz,libtelnet-$(LIBTELNET_VERSION),remote-cmds/libtelnet)

ifneq ($(wildcard $(BUILD_WORK)/remote-cmds/.build_complete),)
remote-cmds:
	@echo "Using previously built remote-cmds."
else
remote-cmds: remote-cmds-setup ncurses libedit
	rm -rf $(BUILD_WORK)/remote-cmds/libtelnet/pk.c
	cd $(BUILD_WORK)/remote-cmds/libtelnet; \
	$(CC) $(CFLAGS) -c *.c -D'__FBSDID=__RCSID' -I. -DHAS_CGETENT -DAUTHENTICATION -DRSA -DFORWARD -DHAVE_STDLIB_H; \
	$(AR) -cr libtelnet.a *.o
	cp -a $(BUILD_WORK)/remote-cmds/libtelnet/libtelnet.a $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_WORK)/remote-cmds/wall.tproj/{ttymsg.c,ttymsg.h} $(BUILD_WORK)/remote-cmds/talkd.tproj
	rm -rf $(BUILD_WORK)/remote-cmds/telnetd.tproj/{authenc.c,strlcpy.c}
	cd $(BUILD_WORK)/remote-cmds && $(CC) $(CFLAGS) -o telnetd telnetd.tproj/*.c $(LDFLAGS) -lcurses -ltelnet -DENV_HACK -DUSE_TERMIO -DNO_UTMP -D'__FBSDID(x)='
	cd $(BUILD_WORK)/remote-cmds && $(CC) $(CFLAGS) -o telnet telnet.tproj/*.c $(LDFLAGS) -ltelnet -lcurses -DUSE_TERMIO

ifneq (,$(findstring macosx,$(PLATFORM)))
	mkdir -p $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX){/Library/LaunchDaemons,/$(MEMO_SUB_PREFIX)/{bin,libexec,/share/man/man{1,8}}}
	cp -a $(BUILD_WORK)/remote-cmds/telnet $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/remote-cmds/telnetd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_WORK)/remote-cmds/telnetd.tproj/telnet.plist $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_WORK)/remote-cmds/telnet.tproj/*.1 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	cp -a $(BUILD_WORK)/remote-cmds/telnetd.tproj/*.8 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/
else
	cd $(BUILD_WORK)/remote-cmds; \
	for tproj in logger talk talkd tftp tftpd wall; do \
		echo "$$tproj" ; \
		$(CC) $(CFLAGS) -I$(BUILD_WORK)/remote-cmds/include -o $$tproj $$tproj.tproj/*.c -D'__FBSDID(x)=' $(LDFLAGS) \
		-ledit -lcurses -DUSE_TERMIO -framework CoreFoundation -framework IOKit; \
	done
	mkdir -p $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX){/Library/LaunchDaemons,/$(MEMO_SUB_PREFIX)/{bin,libexec,/share/man/man{1,8}}}
	cp -a {$(BUILD_WORK)/remote-cmds/talkd.tproj/ntalk.plist,$(BUILD_MISC)/remote-cmds/telnet.plist} $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp -a $(BUILD_WORK)/remote-cmds/{tftpd,telnetd} $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp -a $(BUILD_WORK)/remote-cmds/talkd $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ntalkd
	cp -a $(BUILD_WORK)/remote-cmds/{wall,telnet,tftp,logger} $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/remote-cmds/{tftpd,telnetd,talkd}.tproj/*.8 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/
	cp -a $(BUILD_WORK)/remote-cmds/{wall,telnet,tftp,logger}.tproj/*.1 $(BUILD_STAGE)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
endif
	$(call AFTER_BUILD)
endif

remote-cmds-package: remote-cmds-stage
ifneq (,$(findstring macosx,$(PLATFORM)))
	# remote-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/telnet
	mkdir -p $(BUILD_STAGE)/telnet/$(MEMO_PREFIX){/Library/LaunchDaemons,/$(MEMO_SUB_PREFIX)/{bin,libexec,/share/man/man{1,8}}}

	# remote-cmds.mk Prep telnet
	cp -a $(BUILD_STAGE)/remote-cmds $(BUILD_DIST)/telnet

	# remote-cmds.mk Sign
	$(call SIGN,telnet,general.xml)

	# remote-cmds.mk Make .debs
	$(call PACK,telnet,DEB_REMOTE-CMDS_V)

	# remote-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/remote-cmds
else
	# remote-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/remote-cmds

	# remote-cmds.mk Prep remote-cmds
	cp -a $(BUILD_STAGE)/remote-cmds $(BUILD_DIST)

	# remote-cmds.mk Sign
	$(call SIGN,remote-cmds,general.xml)
	ldid $(MEMO_LDID_EXTRA_FLAGS) -S$(BUILD_MISC)/entitlements/telnetd.xml $(BUILD_DIST)/remote-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/telnetd
	find $(BUILD_DIST)/remote-cmds -name '.ldid*' -type f -delete

	# remote-cmds.mk Make .debs
	$(call PACK,remote-cmds,DEB_REMOTE-CMDS_V)

	# remote-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/remote-cmds

.PHONY: remote-cmds remote-cmds-package

endif
