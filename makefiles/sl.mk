ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += sl
SL_VERSION  := 5.05
DEB_SL_V    ?= $(SL_VERSION)

sl-setup: setup
	$(call GITHUB_ARCHIVE,eyJhb,sl,$(SL_VERSION),$(SL_VERSION))
	$(call EXTRACT_TAR,sl-$(SL_VERSION).tar.gz,sl-$(SL_VERSION),sl)
	mkdir -p $(BUILD_STAGE)/sl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/sl/.build_complete),)
sl:
	@echo "Using previously built sl."
else
sl: sl-setup ncurses
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/sl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sl $(BUILD_WORK)/sl/sl.c $(LDFLAGS) -lncursesw
	touch $(BUILD_WORK)/sl/.build_complete
endif

sl-package: sl-stage
	# sl.mk Package Structure
	rm -rf $(BUILD_DIST)/sl
	mkdir -p $(BUILD_DIST)/sl

	# sl.mk Prep sl
	cp -a $(BUILD_STAGE)/sl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/sl

	# sl.mk Sign
	$(call SIGN,sl,general.xml)

	# sl.mk Make .debs
	$(call PACK,sl,DEB_SL_V)

	# sl.mk Build cleanup
	rm -rf $(BUILD_DIST)/sl

.PHONY: sl sl-package