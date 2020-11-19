ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += zsign
ZSIGN_VERSION   := 20200919
DEB_ZSIGN_V     := 0~$(ZSIGN_VERSION)

ZSIGN_COMMIT_HASH=e2e78a1

zsign-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/zsign-$(ZSIGN_VERSION).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/zsign-$(ZSIGN_VERSION).tar.gz \
			https://github.com/zhlynn/zsign/archive/$(ZSIGN_COMMIT_HASH).tar.gz
	$(call EXTRACT_TAR,zsign-$(ZSIGN_VERSION).tar.gz,zsign-$(ZSIGN_COMMIT_HASH)*,zsign)

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
 
