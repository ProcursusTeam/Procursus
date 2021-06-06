ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += lf
LF_COMMIT   := eaaf08e42504f5986b919ca4690d876424cee4e9
LF_VERSION  := r22.$(shell echo $(LF_COMMIT) | cut -c -7)
DEB_LF_V    ?= 0~$(LF_VERSION)

lf-setup: setup
	$(call GITHUB_ARCHIVE,gokcehan,lf,$(LF_COMMIT),$(LF_COMMIT))
	$(call EXTRACT_TAR,lf-$(LF_COMMIT).tar.gz,lf-$(LF_COMMIT),lf)
	mkdir -p $(BUILD_STAGE)/lf/{etc/profile.d,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin} \
		$(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{lf,man/man1,zsh/site-functions,vim/vimfiles/syntax}

ifneq ($(wildcard $(BUILD_WORK)/lf/.build_complete),)
lf:
	@echo "Using previously built lf."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
lf: lf-setup
else
lf: lf-setup libiosexec
endif
	# Compile lf and move binaries
	cd $(BUILD_WORK)/lf && $(DEFAULT_GOLANG_FLAGS) \
		go build --ldflags="-s -w -X main.gVersion=$(DEB_LF_V)" .
	cp -a $(BUILD_WORK)/lf/lf $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/lf/lf.1 $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	# Copy over other files for zsh, vim, csh, etc
	cp -a $(BUILD_WORK)/lf/etc/lf.zsh \
		$(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_lf
	cp -a $(BUILD_WORK)/lf/etc/lfcd.sh $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/lf
	cp -a $(BUILD_WORK)/lf/etc/lf.vim \
		$(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/vim/vimfiles/syntax
	cp -a $(BUILD_WORK)/lf/etc/{lf.csh,lfcd.csh} $(BUILD_STAGE)/lf/etc/profile.d
	touch $(BUILD_WORK)/lf/.build_complete
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
