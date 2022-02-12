ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += basic-cmds
BASIC-CMDS_VERSION := 56
DEB_BASIC-CMDS_V   ?= $(BASIC-CMDS_VERSION)

basic-cmds-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,basic_cmds,$(BASIC-CMDS_VERSION),basic_cmds-$(BASIC-CMDS_VERSION))
	$(call EXTRACT_TAR,basic_cmds-$(BASIC-CMDS_VERSION).tar.gz,basic_cmds-basic_cmds-$(BASIC-CMDS_VERSION),basic-cmds)
	mkdir -p $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/basic-cmds/.build_complete),)
basic-cmds:
	@echo "Using previously built basic-cmds."
else
basic-cmds: basic-cmds-setup ncurses
	mkdir -p $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1/}
	cd $(BUILD_WORK)/basic-cmds; \
	for bin in mesg write uudecode uuencode; do \
		$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c; \
		$(INSTALL) -Dm644 $$bin/$$bin.1 $(BUILD_STAGE)/basic-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/; \
	done
	$(call AFTER_BUILD)
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
