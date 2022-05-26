ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += chezmoi
CHEZMOI_COMMIT  := 8714b95999fcfc7247a3ee70e4232f438b610c82 
CHEZMOI_VERSION := 2.12.1
DEB_CHEZMOI_V   ?= $(CHEZMOI_VERSION)

chezmoi-setup: setup
	$(call GITHUB_ARCHIVE,twpayne,chezmoi,$(CHEZMOI_VERSION),v$(CHEZMOI_VERSION))
	$(call EXTRACT_TAR,chezmoi-$(CHEZMOI_VERSION).tar.gz,chezmoi-$(CHEZMOI_VERSION),chezmoi)
	mkdir -p $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{zsh/site-functions,bash-completion/completions,fish/vendor_completions.d}}

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
		go build -ldflags "-X main.version=$(CHEZMOI_VERSION) \
			-X main.commit=$(CHEZMOI_COMMIT) \
			-X main.builtBy=Procursus \
			-X main.date=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)"
	cd $(BUILD_WORK)/chezmoi && \
		CGO_CC="$(CC_FOR_BUILD)" CGO_CFLAGS="$(CFLAGS_FOR_BUILD)" CGO_CPPFLAGS="$(CPPFLAGS_FOR_BUILD)" CGO_LDFLAGS="$(LDFLAGS_FOR_BUILD)" \
		go build -o chezmoi-host

	$(BUILD_WORK)/chezmoi/chezmoi-host completion zsh > $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_chezmoi
	$(BUILD_WORK)/chezmoi/chezmoi-host completion bash > $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/chezmoi
	$(BUILD_WORK)/chezmoi/chezmoi-host completion fish > $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/chezmoi.fish
	cp -a $(BUILD_WORK)/chezmoi/chezmoi $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
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
