ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS       += text-cmds
TEXT-CMDS_VERSION := 106
DEB_TEXT-CMDS_V   ?= 1:$(TEXT-CMDS_VERSION)

text-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/text_cmds/text_cmds-$(TEXT-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,text_cmds-$(TEXT-CMDS_VERSION).tar.gz,text_cmds-$(TEXT-CMDS_VERSION),text-cmds)
	sed -i 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|' $(BUILD_WORK)/text-cmds/ee/ee.c
	mkdir -p $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX){/sbin,$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,6}}}

ifneq ($(wildcard $(BUILD_WORK)/text-cmds/.build_complete),)
text-cmds:
	@echo "Using previously built text-cmds."
else
text-cmds: text-cmds-setup ncurses
	-cd $(BUILD_WORK)/text-cmds; \
	for bin in banner col colrm column ee lam look md5 rev rs ul unvis vis; do \
		case $$bin in \
			ee) EXTRAFLAGS="-lncursesw";; \
			md5) EXTRAFLAGS="$(BUILD_WORK)/text-cmds/md5/commoncrypto.c";; \
			ul) EXTRAFLAGS="-lncursesw";; \
			vis) EXTRAFLAGS="$(BUILD_WORK)/text-cmds/vis/foldit.c";; \
		esac; \
		$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/$$bin.c $$EXTRAFLAGS -DHAS_NCURSES -DHAS_UNISTD -DHAS_STDARG -DHAS_STDLIB -DHAS_SYS_WAIT; \
		cp -af $$bin/$$bin.1 $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 2>/dev/null; \
		cp -af $$bin/$$bin.6 $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man6 2>/dev/null; \
	done
	mv $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/md5 $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)/sbin/md5
	for cmd in rmd160 sha1 sha256; do \
		$(LN_S) md5 $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)/sbin/$$cmd; \
		$(LN_S) md5.1.zst $(BUILD_STAGE)/text-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$$cmd.1.zst; \
	done
	$(call AFTER_BUILD)
endif

text-cmds-package: text-cmds-stage
	# text-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/text-cmds
	
	# text-cmds.mk Prep text-cmds
	cp -a $(BUILD_STAGE)/text-cmds $(BUILD_DIST)
	
	# text-cmds.mk Sign
	$(call SIGN,text-cmds,general.xml)
	
	# text-cmds.mk Make .debs
	$(call PACK,text-cmds,DEB_TEXT-CMDS_V)
	
	# text-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/text-cmds

.PHONY: text-cmds text-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
