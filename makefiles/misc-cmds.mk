ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += misc-cmds
MISC-CMDS_VERSION := 34
DEB_MISC-CMDS_V   ?= $(MISC-CMDS_VERSION)

misc-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/misc_cmds/misc_cmds-$(MISC-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,misc_cmds-$(MISC-CMDS_VERSION).tar.gz,misc_cmds-$(MISC-CMDS_VERSION),misc-cmds)
	mkdir -p $(BUILD_STAGE)/misc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{man/man1,misc}}
	sed -i 's|#include <calendar.h>|#include "calendar.h"|g' $(BUILD_WORK)/misc-cmds/ncal/ncal.c
	sed -i '1 i\typedef unsigned int u_int;' $(BUILD_WORK)/misc-cmds/leave/leave.c
	sed -i "s|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g" $(BUILD_WORK)/misc-cmds/{calendar,units}/pathnames.h

ifneq ($(wildcard $(BUILD_WORK)/misc-cmds/.build_complete),)
misc-cmds:
	@echo "Using previously built misc-cmds."
else
misc-cmds: misc-cmds-setup ncurses
	@# tsort conflics with coreutils
	cd $(BUILD_WORK)/misc-cmds; \
	for bin in calendar leave ncal units; do \
		$(CC) $(LDFLAGS) $(CFLAGS) -o $(BUILD_STAGE)/misc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -lncurses; \
		cp $(BUILD_WORK)/misc-cmds/$$bin/$$bin.1 $(BUILD_STAGE)/misc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/$$bin.1 ;\
	done
	cp -a $(BUILD_WORK)/misc-cmds/calendar/calendars $(BUILD_STAGE)/misc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/calendar
	cp -a $(BUILD_WORK)/misc-cmds/units/units.lib $(BUILD_STAGE)/misc-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/misc
	$(call AFTER_BUILD)
endif

misc-cmds-package: misc-cmds-stage
	# misc-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/misc-cmds

	# misc-cmds.mk Prep misc-cmds
	cp -a $(BUILD_STAGE)/misc-cmds $(BUILD_DIST)

	# misc-cmds.mk Sign
	$(call SIGN,misc-cmds,general.xml)

	# misc-cmds.mk Make .debs
	$(call PACK,misc-cmds,DEB_MISC-CMDS_V)

	# misc-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/misc-cmds

.PHONY: misc-cmds misc-cmds-package
