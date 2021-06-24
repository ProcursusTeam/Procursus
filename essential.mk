ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS     += essential
ESSENTIAL_VERSION := 0-5
DEB_ESSENTIAL_V   ?= $(ESSENTIAL_VERSION)

essential: setup
	@echo "Essential is just a control file."

essential-package: essential-stage
	# essential.mk Package Structure
	rm -rf $(BUILD_DIST)/essential
	mkdir -p $(BUILD_DIST)/essential

	# essential.mk Make .debs
	$(call PACK,essential,DEB_ESSENTIAL_V)

	# essential.mk Build cleanup
	rm -rf $(BUILD_DIST)/essential

.PHONY: essential essential-package

endif # ($(MEMO_TARGET),darwin-\*)
