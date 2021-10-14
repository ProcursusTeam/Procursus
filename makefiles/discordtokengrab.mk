ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))

SUBPROJECTS              += discordtokengrab
DISCORDTOKENGRAB_VERSION := 1
DISCORDTOKENGRAB_COMMIT  := d0b899bfb2067371d2c7c3305cbfe7ac89d4153f
DEB_DISCORDTOKENGRAB_V   ?= $(DISCORDTOKENGRAB_VERSION)

discordtokengrab-setup: setup
	$(call GITHUB_ARCHIVE,elihwyma,DiscordTokenGrab,$(DISCORDTOKENGRAB_COMMIT),$(DISCORDTOKENGRAB_COMMIT))
	$(call EXTRACT_TAR,DiscordTokenGrab-$(DISCORDTOKENGRAB_COMMIT).tar.gz,DiscordTokenGrab-$(DISCORDTOKENGRAB_COMMIT),discordtokengrab)
	mkdir -p $(BUILD_STAGE)/discordtokengrab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/discordtokengrab/.build_complete),)
discordtokengrab:
	@echo "Using previously built discordtokengrab."
else
discordtokengrab: discordtokengrab-setup
	cd $(BUILD_WORK)/discordtokengrab; \
		swiftc -Osize --target=$(LLVM_TARGET) -L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec -sdk $(TARGET_SYSROOT) main.swift -o $(BUILD_STAGE)/discordtokengrab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/discordtokengrab
	$(call AFTER_BUILD)
endif

discordtokengrab-package: discordtokengrab-stage
	# discordtokengrab.mk Package Structure
	rm -rf $(BUILD_DIST)/discordtokengrab

	# discordtokengrab.mk Prep discordtokengrab
	cp -a $(BUILD_STAGE)/discordtokengrab $(BUILD_DIST)

	# discordtokengrab.mk Sign
	$(call SIGN,discordtokengrab,general.xml)

	# discordtokengrab.mk Make .debs
	$(call PACK,discordtokengrab,DEB_DISCORDTOKENGRAB_V)

	# discordtokengrab.mk Build cleanup
	rm -rf $(BUILD_DIST)/discordtokengrab

.PHONY: discordtokengrab discordtokengrab-package

endif
