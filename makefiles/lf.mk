ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += lf
LF_RELEASE  := r32
LF_VERSION  := $(shell echo $(LF_RELEASE) | cut -c 2-3)
DEB_LF_V    ?= $(LF_VERSION)

lf-setup: setup
	$(call GITHUB_ARCHIVE,gokcehan,lf,$(LF_RELEASE),$(LF_RELEASE))
	$(call EXTRACT_TAR,lf-$(LF_RELEASE).tar.gz,lf-$(LF_RELEASE),lf)

ifneq ($(wildcard $(BUILD_WORK)/lf/.build_complete),)
lf:
	@echo "Using previously built lf."
else
lf: lf-setup
	cd $(BUILD_WORK)/lf && $(DEFAULT_GOLANG_FLAGS) go build \
		-trimpath \
		-ldflags "-s -w -X main.gVersion=$(LF_RELEASE)" \
		-o $(BUILD_WORK)/lf/lf
	$(INSTALL) -Dm755 $(BUILD_WORK)/lf/lf -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/lf.1 -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.zsh $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lfcd.sh -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.vim -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/vim/vimfiles/syntax
	$(LN_S) syntax $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/vim/vimfiles/ftdetect
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.bash $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf{,cd}.csh -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)/etc/profile.d
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.fish -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lfcd.fish -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_functions.d
	$(call AFTER_BUILD)
endif

lf-package: lf-stage
	# lf.mk Package Structure
	rm -rf $(BUILD_DIST)/lf

	# lf.mk Prep lf
	cp -a $(BUILD_STAGE)/lf $(BUILD_DIST)

	# lf.mk Sign
	$(call SIGN,lf,general.xml)

	# lf.mk Make .debs
	$(call PACK,lf,DEB_LF_V)

	# lf.mk Build cleanup
	rm -rf $(BUILD_DIST)/lf

.PHONY: lf lf-package
