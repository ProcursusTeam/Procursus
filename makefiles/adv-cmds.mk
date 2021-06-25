ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += adv-cmds
ADV-CMDS_VERSION := 176
DEB_ADV-CMDS_V   ?= $(ADV-CMDS_VERSION)

adv-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/adv_cmds/adv_cmds-$(ADV-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,adv_cmds-$(ADV-CMDS_VERSION).tar.gz,adv_cmds-$(ADV-CMDS_VERSION),adv-cmds)
	mkdir -p $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/adv-cmds/include
	cp -a $(MACOSX_SYSROOT)/usr/include/tzfile.h $(BUILD_WORK)/adv-cmds/include

ifneq ($(wildcard $(BUILD_WORK)/adv-cmds/.build_complete),)
adv-cmds:
	@echo "Using previously built adv-cmds."
else
adv-cmds: adv-cmds-setup ncurses
	cd $(BUILD_WORK)/adv-cmds; \
	$(CXX) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/locale locale/*.cc; \
	$(CC) $(CFLAGS) -L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tabs tabs/*.c -lncursesw; \
	for bin in finger last lsvfs cap_mkdb; do \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D'__FBSDID(x)='; \
	done
	cd $(BUILD_WORK)/adv-cmds/mklocale; \
	yacc -d yacc.y; \
	lex lex.l
	$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/adv-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mklocale $(BUILD_WORK)/adv-cmds/mklocale/*.c -D'__FBSDID(x)='
	touch $(BUILD_WORK)/adv-cmds/.build_complete
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