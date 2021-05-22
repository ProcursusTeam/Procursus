ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += basic-cmds
BASIC-CMDS_VERSION := 55
DEB_BASIC-CMDS_V   ?= $(BASIC-CMDS_VERSION)-1

basic-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/basic_cmds/basic_cmds-$(BASIC-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,basic_cmds-$(BASIC-CMDS_VERSION).tar.gz,basic_cmds-$(BASIC-CMDS_VERSION),basic-cmds)
	mkdir -p $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/basic-cmds/.build_complete),)
basic-cmds:
	@echo "Using previously built basic-cmds."
else
basic-cmds: basic-cmds-setup ncurses
	mkdir -p $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cd $(BUILD_WORK)/basic-cmds; \
	for bin in mesg write uudecode uuencode; do \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -o $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c; \
	done
	touch $(BUILD_WORK)/basic-cmds/.build_complete
endif

basic-cmds-package: basic-cmds-stage
	# basic-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/basic-cmds

	# basic-cmds.mk Prep basic-cmds
	cp -a $(BUILD_STAGE)/basic-cmds $(BUILD_DIST)

	# basic-cmds.mk Sign
	$(call SIGN,basic-cmds,general.xml)

	# basic-cmds.mk Make .debs
	$(call PACK,basic-cmds,DEB_BASIC-CMDS_V)

	# basic-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/basic-cmds

.PHONY: basic-cmds basic-cmds-package
