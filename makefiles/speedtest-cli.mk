ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += speedtest-cli
SPEEDTEST-CLI_VERSION := 2.1.3
DEB_SPEEDTEST-CLI_V   ?= $(SPEEDTEST-CLI_VERSION)

speedtest-cli-setup: setup
	$(call GITHUB_ARCHIVE,sivel,speedtest-cli,$(SPEEDTEST-CLI_VERSION),v$(SPEEDTEST-CLI_VERSION))
	$(call EXTRACT_TAR,speedtest-cli-$(SPEEDTEST-CLI_VERSION).tar.gz,speedtest-cli-$(SPEEDTEST-CLI_VERSION),speedtest-cli)

ifneq ($(wildcard $(BUILD_WORK)/speedtest-cli/.build_complete),)
speedtest-cli:
	@echo "Using previously built speedtest-cli."
else
speedtest-cli: speedtest-cli-setup
	$(INSTALL) -Dm 755 $(BUILD_WORK)/speedtest-cli/speedtest.py "$(BUILD_STAGE)/speedtest-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/speedtest-cli"
	ln -s speedtest-cli $(BUILD_STAGE)/speedtest-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/speedtest
	$(INSTALL) -Dm 644 $(BUILD_WORK)/speedtest-cli/speedtest-cli.1 -t "$(BUILD_STAGE)/speedtest-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1"
	touch $(BUILD_WORK)/speedtest-cli/.build_complete
endif

speedtest-cli-package: speedtest-cli-stage
	# speedtest-cli.mk Package Structure
	rm -rf $(BUILD_DIST)/speedtest-cli
	mkdir -p $(BUILD_DIST)/speedtest-cli

	# speedtest-cli.mk Prep speedtest-cli
	cp -a $(BUILD_STAGE)/speedtest-cli $(BUILD_DIST)

	# speedtest-cli.mk Make .debs
	$(call PACK,speedtest-cli,DEB_SPEEDTEST-CLI_V)

	# speedtest-cli.mk Build cleanup
	rm -rf $(BUILD_DIST)/speedtest-cli

.PHONY: speedtest-cli speedtest-cli-package
