ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += airdrop-cli
AIRDROP_CLI_VERSION := 1.0.1
DEB_AIRDROP_CLI_V   ?= $(AIRDROP_CLI_VERSION)

airdrop-cli-setup: setup
	$(call GITHUB_ARCHIVE,vldmrkl,airdrop-cli,$(AIRDROP_CLI_VERSION),$(AIRDROP_CLI_VERSION))
	$(call EXTRACT_TAR,airdrop-cli-$(AIRDROP_CLI_VERSION).tar.gz,airdrop-cli-$(AIRDROP_CLI_VERSION),airdrop-cli)

ifneq ($(wildcard $(BUILD_WORK)/airdrop-cli/.build_complete),)
airdrop-cli:
	@echo "Using previously built airdrop-cli."
else
airdrop-cli: airdrop-cli-setup
	cd $(BUILD_WORK)/airdrop-cli && swift build -c release --sdk $(TARGET_SYSROOT)  --disable-sandbox
	 mkdir -p $(BUILD_STAGE)/airdrop-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	 cp $(BUILD_WORK)/airdrop-cli/.build/release/airdrop $(BUILD_STAGE)/airdrop-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	 chmod +x $(BUILD_STAGE)/airdrop-cli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
		$(call AFTER_BUILD)
endif

airdrop-cli-package: airdrop-cli-stage
	# airdrop-cli.mk Package Structure
	rm -rf $(BUILD_DIST)/airdrop-cli

	# airdrop-cli.mk Prep airdrop-cli
	cp -a $(BUILD_STAGE)/airdrop-cli $(BUILD_DIST)

	# airdrop-cli.mk Sign
	$(call SIGN,airdrop-cli,general.xml)

	# airdrop-cli.mk Make .debs
	$(call PACK,airdrop-cli,DEB_AIRDROP_CLI_V)

	# airdrop-cli.mk Build cleanup
	rm -rf $(BUILD_DIST)/airdrop-cli

.PHONY: airdrop-cli airdrop-cli-package
