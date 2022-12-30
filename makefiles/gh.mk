ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += gh
GH_VERSION  := 2.21.1
DEB_GH_V    ?= $(GH_VERSION)

gh-setup: setup
	$(call GITHUB_ARCHIVE,cli,cli,$(GH_VERSION),v$(GH_VERSION),gh)
	$(call EXTRACT_TAR,gh-$(GH_VERSION).tar.gz,cli-$(GH_VERSION),gh)
	mkdir -p $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{zsh/site-functions,bash-completion/completions,fish/vendor_completions.d}

ifneq ($(wildcard $(BUILD_WORK)/gh/.build_complete),)
gh:
	@echo "Using previously built gh."
else
gh: gh-setup
	cd $(BUILD_WORK)/gh && CGO_CC="$(CC_FOR_BUILD)" go build \
		-trimpath \
		-o $(BUILD_WORK)/gh/bin/gh-host \
		$(BUILD_WORK)/gh/cmd/gh
	cd $(BUILD_WORK)/gh && go run $(BUILD_WORK)/gh/cmd/gen-docs \
		--man-page \
		--doc-path $(BUILD_WORK)/gh/share/man/man1/
	sed -e "66s|manpages||" -i $(BUILD_WORK)/gh/Makefile
	+$(MAKE) -C $(BUILD_WORK)/gh \
		$(DEFAULT_GOLANG_FLAGS) \
		GH_VERSION="$(DEB_GH_V)"
	+$(MAKE) -C $(BUILD_WORK)/gh install \
		prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/gh"
	$(BUILD_WORK)/gh/bin/gh-host completion zsh > $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_gh
	$(BUILD_WORK)/gh/bin/gh-host completion bash > $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/gh
	$(BUILD_WORK)/gh/bin/gh-host completion fish > $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/gh.fish
	$(call AFTER_BUILD)
endif

gh-package: gh-stage
	# gh.mk Package Structure
	rm -rf $(BUILD_DIST)/gh

	# gh.mk Prep gh
	cp -a $(BUILD_STAGE)/gh $(BUILD_DIST)

	# gh.mk Sign
	$(call SIGN,gh,general.xml)

	# gh.mk Make .debs
	$(call PACK,gh,DEB_GH_V)

	# gh.mk Build cleanup
	rm -rf $(BUILD_DIST)/gh

.PHONY: gh gh-package
