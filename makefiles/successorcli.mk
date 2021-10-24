ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1600 ] && echo 1),1)

SUBPROJECTS          += successorcli
SUCCESSORCLI_VERSION := 1.0.2
SUCCESSORCLI_COMMIT  := 800db26122ee11cdb55a744b157a63d3f594cbaf
DEB_SUCCESSORCLI_V   ?= $(SUCCESSORCLI_VERSION)

successorcli-setup: setup
	$(call GITHUB_ARCHIVE,dabezt31,SuccessorCLI,$(SUCCESSORCLI_COMMIT),$(SUCCESSORCLI_COMMIT))
	$(call EXTRACT_TAR,SuccessorCLI-$(SUCCESSORCLI_COMMIT).tar.gz,SuccessorCLI-$(SUCCESSORCLI_COMMIT),successorcli)
	mkdir -p $(BUILD_STAGE)/successorcli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin

ifneq ($(wildcard $(BUILD_WORK)/successorcli/.build_complete),)
successorcli:
	@echo "Using previously built successorcli."
else
successorcli: successorcli-setup
	cd $(BUILD_WORK)/successorcli; \
		swiftc -Osize --target=$(LLVM_TARGET) -L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec -sdk $(TARGET_SYSROOT) src/*.swift -import-objc-header src/Bridge.h -L$(BUILD_MISC)/successorcli -lDiskImages2 -lSpringBoardServices -o $(BUILD_STAGE)/successorcli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/successorcli
	$(call AFTER_BUILD)
endif

successorcli-package: successorcli-stage
	# successorcli.mk Package Structure
	rm -rf $(BUILD_DIST)/successorcli

	# successorcli.mk Prep successorcli
	cp -a $(BUILD_STAGE)/successorcli $(BUILD_DIST)

	# successorcli.mk Sign
	$(call SIGN,successorcli,successorcli.xml)

	# successorcli.mk Make .debs
	$(call PACK,successorcli,DEB_SUCCESSORCLI_V)

	# successorcli.mk Build cleanup
	rm -rf $(BUILD_DIST)/successorcli

.PHONY: successorcli successorcli-package

endif
endif
