ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += sl
SL_VERSION  := 5.06
SL_COMMIT   := 23ec2c51d79c1d015f3c38aef4a94e939115367b
DEB_SL_V    ?= $(SL_VERSION)

sl-setup: setup
	# Use previous fork if Keto ever PRs the changes
	$(call GITHUB_ARCHIVE,TheRealKeto,sl,$(SL_COMMIT),$(SL_COMMIT))
	$(call EXTRACT_TAR,sl-$(SL_COMMIT).tar.gz,sl-$(SL_COMMIT),sl)

ifneq ($(wildcard $(BUILD_WORK)/sl/.build_complete),)
sl:
	@echo "Using previously built sl."
else
sl: sl-setup ncurses
	+$(MAKE) -C $(BUILD_WORK)/sl install \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		NCURSES_FLAG=-lncursesw \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/sl"
	$(call AFTER_BUILD)
endif

sl-package: sl-stage
	# sl.mk Package Structure
	rm -rf $(BUILD_DIST)/sl

	# sl.mk Prep sl
	cp -a $(BUILD_STAGE)/sl $(BUILD_DIST)

	# sl.mk Sign
	$(call SIGN,sl,general.xml)

	# sl.mk Make .debs
	$(call PACK,sl,DEB_SL_V)

	# sl.mk Build cleanup
	rm -rf $(BUILD_DIST)/sl

.PHONY: sl sl-package
