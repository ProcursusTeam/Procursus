ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += adv-cmds
ADV-CMDS_VERSION := 199.0.1
DEB_ADV-CMDS_V   ?= $(ADV-CMDS_VERSION)-1

adv-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,adv_cmds,$(ADV-CMDS_VERSION),adv_cmds-$(ADV-CMDS_VERSION))
	$(call EXTRACT_TAR,adv_cmds-$(ADV-CMDS_VERSION).tar.gz,adv_cmds-adv_cmds-$(ADV-CMDS_VERSION),adv-cmds)
	mkdir -p $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,5}/}
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/adv-cmds/include,https://github.com/apple-oss-distributions/Libc/raw/Libc-1507.100.9/{nls/FreeBSD/msgcat$(comma)locale/FreeBSD/collate}.h)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/adv-cmds/colldef,https://github.com/apple-oss-distributions/Liby/raw/Liby-20/libyywrap.c)
	sed -i 's|/usr/share/locale|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale|g' $(BUILD_WORK)/adv-cmds/locale/locale.cc

ifneq ($(wildcard $(BUILD_WORK)/adv-cmds/.build_complete),)
adv-cmds:
	@echo "Using previously built adv-cmds."
else
adv-cmds: adv-cmds-setup ncurses
	cd $(BUILD_WORK)/adv-cmds/colldef; \
		yacc -d parse.y; \
		lex scan.l;
	cd $(BUILD_WORK)/adv-cmds; \
	$(CXX) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/locale locale/*.cc; \
	$(INSTALL) -Dm644 locale/locale.1 $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	$(CC) $(CFLAGS) $(LDFLAGS) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tabs tabs/*.c -lncursesw; \
	$(INSTALL) -Dm644 tabs/tabs.1 $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	for bin in finger last lsvfs cap_mkdb gencat colldef; do \
		echo $${bin}; \
		$(CC) $(CFLAGS) $(LDFLAGS) -I$(BUILD_WORK)/adv-cmds/include -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)='; \
		$(INSTALL) -Dm644 $$bin/$$bin.1 $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1; \
	done; \
	$(INSTALL) -Dm644 finger/finger.conf.5 $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5; \
	cd $(BUILD_WORK)/adv-cmds/mklocale; \
	yacc -d yacc.y; \
	lex lex.l
	$(CC) $(CFLAGS) $(LDFLAGS) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mklocale $(BUILD_WORK)/adv-cmds/mklocale/*.c -D'__FBSDID(x)='
	$(INSTALL) -Dm644 $(BUILD_WORK)/adv-cmds/mklocale/mklocale.1 $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD)
endif

adv-cmds-package: adv-cmds-stage
	# adv-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/adv-cmds

	# adv-cmds.mk Prep adv-cmds
	cp -a $(BUILD_STAGE)/adv-cmds $(BUILD_DIST)

	# adv-cmds.mk Sign
	$(call SIGN,adv-cmds,general.xml)

	# adv-cmds.mk Make .debs
	$(call PACK,adv-cmds,DEB_ADV-CMDS_V)

	# adv-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/adv-cmds

.PHONY: adv-cmds adv-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)
