ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += chezmoi
CHEZMOI_VERSION := 2.0.10
DEB_CHEZMOI_V   ?= $(CHEZMOI_VERSION)

chezmoi-setup: setup
	$(call GITHUB_ARCHIVE,twpayne,chezmoi,$(CHEZMOI_VERSION),v$(CHEZMOI_VERSION))
	$(call EXTRACT_TAR,chezmoi-v$(CHEZMOI_VERSION).tar.gz,chezmoi-$(CHEZMOI_VERSION),chezmoi)
	mkdir -p $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/chezmoi/.build_complete),)
chezmoi:
	@echo "Using previously built chezmoi."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
chezmoi: chezmoi-setup
else
chezmoi: chezmoi-setup libiosexec
endif
	cd $(BUILD_WORK)/chezmoi && go get -d -v .
	cd $(BUILD_WORK)/chezmoi && \
		$(DEFAULT_GOLANG_FLAGS) \
		go build
	cp -a $(BUILD_WORK)/chezmoi/chezmoi $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/chezmoi/.build_complete
endif

chezmoi-package: chezmoi-stage
	# chezmoi.mk Package Structure
	rm -rf $(BUILD_DIST)/chezmoi

	# chezmoi.mk Prep chezmoi
	cp -a $(BUILD_STAGE)/chezmoi $(BUILD_DIST)/

	# chezmoi.mk Sign
	$(call SIGN,chezmoi,general.xml)

	# chezmoi.mk Make .debs
	$(call PACK,chezmoi,DEB_CHEZMOI_V)

	# chezmoi.mk Build cleanup
	rm -rf $(BUILD_DIST)/chezmoi

.PHONY: chezmoi chezmoi-package
