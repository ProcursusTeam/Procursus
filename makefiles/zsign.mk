ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += zsign
ZSIGN_COMMIT  := 60a1fbd5f018fdd273c16b043a95ea53a528b02e
ZSIGN_VERSION := 0~20210609.$(shell echo $(ZSIGN_COMMIT) | cut -c -7)
DEB_ZSIGN_V   := $(ZSIGN_VERSION)

zsign-setup: setup
	$(call GITHUB_ARCHIVE,zhlynn,zsign,$(ZSIGN_COMMIT),$(ZSIGN_COMMIT))
	$(call EXTRACT_TAR,zsign-$(ZSIGN_COMMIT).tar.gz,zsign-$(ZSIGN_COMMIT)*,zsign)

ifneq ($(wildcard $(BUILD_WORK)/zsign/.build_complete),)
zsign:
	@echo "Using previously built zsign."
else
zsign: zsign-setup openssl
	cd $(BUILD_WORK)/zsign && $(CXX) $(CXXFLAGS) \
		*.cpp \
		common/*.cpp \
		$(LDFLAGS) \
		-lcrypto \
		-o zsign
	mkdir -p $(BUILD_STAGE)/zsign/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_WORK)/zsign/zsign $(BUILD_STAGE)/zsign/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/zsign/.build_complete
endif

zsign-package: zsign-stage
	# zsign.mk Package Structure
	rm -rf $(BUILD_DIST)/zsign
	mkdir -p $(BUILD_DIST)/zsign

	# zsign.mk Prep zsign
	cp -a $(BUILD_STAGE)/zsign $(BUILD_DIST)

	# zsign.mk Sign
	$(call SIGN,zsign,general.xml)

	# zsign.mk Make .debs
	$(call PACK,zsign,DEB_ZSIGN_V)

	# zsign.mk Build cleanup
	rm -rf $(BUILD_DIST)/zsign

.PHONY: zsign zsign-package
