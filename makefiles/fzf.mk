ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += fzf
FZF_VERSION  := 0.25.0
DEB_FZF_V    ?= $(FZF_VERSION)

fzf-setup: setup
	$(call GITHUB_ARCHIVE,junegunn,fzf,$(FZF_VERSION),$(FZF_VERSION))
	$(call EXTRACT_TAR,fzf-$(FZF_VERSION).tar.gz,fzf-$(FZF_VERSION),fzf)
	mkdir -p $(BUILD_STAGE)/fzf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){/share,/bin}

ifneq ($(wildcard $(BUILD_WORK)/fzf/.build_complete),)
fzf:
	@echo "Using previously built fzf."
else
fzf: fzf-setup
	cd $(BUILD_WORK)/fzf && $(DEFAULT_GOLANG_FLAGS) go build \
			-ldflags "-s -w -X main.version=$(FZF_VERSION) -X main.revision=Procursus"
	$(INSTALL) -Dm755 $(BUILD_WORK)/fzf/{/fzf,/bin/fzf-tmux} $(BUILD_STAGE)/fzf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(CP) -a $(BUILD_WORK)/fzf/man $(BUILD_STAGE)/fzf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	touch $(BUILD_WORK)/fzf/.build_complete
endif

fzf-package: fzf-stage
	# fzf.mk Package Structure
	rm -rf $(BUILD_DIST)/fzf
	mkdir -p $(BUILD_DIST)

	# fzf.mk Prep fzf
	cp -a $(BUILD_STAGE)/fzf $(BUILD_DIST)

	# fzf.mk Sign
	$(call SIGN,fzf,general.xml)

	# fzf.mk Make .debs
	$(call PACK,fzf,DEB_FZF_V)

	# fzf.mk Build cleanup
	rm -rf $(BUILD_DIST)/fzf

.PHONY: fzf fzf-package
