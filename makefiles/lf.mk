ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += lf
LF_VERSION  := r27
DEB_LF_V    ?= 0~$(LF_VERSION)

lf-setup: setup
	$(call GITHUB_ARCHIVE,gokcehan,lf,$(LF_VERSION),$(LF_VERSION))
	$(call EXTRACT_TAR,lf-$(LF_VERSION).tar.gz,lf-$(LF_VERSION),lf)

ifneq ($(wildcard $(BUILD_WORK)/lf/.build_complete),)
lf:
	@echo "Using previously built lf."
else
lf: lf-setup
	# Compile lf and move binaries
	cd $(BUILD_WORK)/lf && $(DEFAULT_GOLANG_FLAGS) go build \
		-o releases/bin/lf \
		-ldflags="-s -w -X main.gVersion=$(DEB_LF_V)" .
	$(INSTALL) -Dm755 $(BUILD_WORK)/lf/releases/bin/lf \
	    $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/lf.1 \
	    -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	# Copy over other files for zsh, vim, csh, etc
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.zsh \
	    $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lfcd.sh \
	    -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.vim \
	    -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/vim/vimfiles/syntax
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/lf.bash \
	    $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/completions/lf
	$(INSTALL) -Dm644 $(BUILD_WORK)/lf/etc/{lf.csh,lfcd.csh} -t $(BUILD_STAGE)/lf/$(MEMO_PREFIX)/etc/profile.d
	$(call AFTER_BUILD)
endif

lf-package: lf-stage
	# lf.mk Package Structure
	rm -rf $(BUILD_DIST)/lf
	cp -a $(BUILD_STAGE)/lf $(BUILD_DIST)

	# lf.mk Sign
	$(call SIGN,lf,general.xml)

	# lf.mk Make .debs
	$(call PACK,lf,DEB_LF_V)

	# lf.mk Build Cleanup
	rm -rf $(BUILD_DIST)/lf

.PHONY: lf lf-package
