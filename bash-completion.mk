ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += bash-completion
BASH-COMPLETION_VERSION := 2.11
DEB_BASH-COMPLETION_V   ?= $(BASH-COMPLETION_VERSION)

bash-completion-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/scop/bash-completion/releases/download/$(BASH-COMPLETION_VERSION)/bash-completion-$(BASH-COMPLETION_VERSION).tar.xz
	$(call EXTRACT_TAR,bash-completion-$(BASH-COMPLETION_VERSION).tar.xz,bash-completion-$(BASH-COMPLETION_VERSION),bash-completion)

ifneq ($(wildcard $(BUILD_WORK)/bash-completion/.build_complete),)
bash-completion:
	@echo "Using previously built bash-completion."
else
bash-completion: bash-completion-setup bash
	cd $(BUILD_WORK)/bash-completion && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/bash-completion
	+$(MAKE) -C $(BUILD_WORK)/bash-completion install \
		DESTDIR=$(BUILD_STAGE)/bash-completion
	touch $(BUILD_WORK)/bash-completion/.build_complete
endif

bash-completion-package: bash-completion-stage
	# bash-completion.mk Package Structure
	rm -rf $(BUILD_DIST)/bash-completion
	mkdir -p $(BUILD_DIST)/bash-completion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bash-completion.mk Prep bash-completion
	cp -a $(BUILD_STAGE)/bash-completion/$(MEMO_PREFIX)/etc $(BUILD_DIST)/bash-completion/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/bash-completion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/bash-completion/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bash-completion.mk Make .debs
	$(call PACK,bash-completion,DEB_BASH-COMPLETION_V)

	# bash-completion.mk Build cleanup
	rm -rf $(BUILD_DIST)/bash-completion

.PHONY: bash-completion bash-completion-package
