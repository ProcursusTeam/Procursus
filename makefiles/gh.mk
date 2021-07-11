ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += gh
GH_VERSION  := 1.9.2
DEB_GH_V    ?= $(GH_VERSION)

gh-setup: setup
	$(call GITHUB_ARCHIVE,cli,cli,$(GH_VERSION),v$(GH_VERSION),gh)
	$(call EXTRACT_TAR,gh-$(GH_VERSION).tar.gz,cli-$(GH_VERSION),gh)
	mkdir -p $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/gh/.build_complete),)
gh:
	@echo "Using previously built gh."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
gh: gh-setup
else
gh: gh-setup libiosexec
endif
	+$(MAKE) -C $(BUILD_WORK)/gh bin/gh \
		$(DEFAULT_GOLANG_FLAGS)
	+unset CC CXX CFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/gh manpages
	$(CP) -a $(BUILD_WORK)/gh/bin/gh $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(CP) -a $(BUILD_WORK)/gh/share $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/gh/.build_complete
endif

gh-package: gh-stage
	# gh.mk Package Structure
	rm -rf $(BUILD_DIST)/gh
	mkdir -p $(BUILD_DIST)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# gh.mk Prep gh
	cp -a $(BUILD_STAGE)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/gh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# gh.mk Sign
	$(call SIGN,gh,general.xml)

	# gh.mk Make .debs
	$(call PACK,gh,DEB_GH_V)

	# gh.mk Build cleanup
	rm -rf $(BUILD_DIST)/gh

.PHONY: gh gh-package
