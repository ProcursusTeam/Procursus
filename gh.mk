ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += gh
GH_VERSION  := 1.1.0
DEB_GH_V    ?= $(GH_VERSION)

gh-setup: setup
	wget -q -nc -O$(BUILD_SOURCE)/gh-$(GH_VERSION).tar.gz \
		https://github.com/cli/cli/archive/v$(GH_VERSION).tar.gz
	$(call EXTRACT_TAR,gh-$(GH_VERSION).tar.gz,cli-$(GH_VERSION),gh)
	mkdir -p $(BUILD_STAGE)/gh/usr/bin

ifneq ($(ARCHES),arm64)
gh:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(UNAME),Darwin)
gh:
	@echo "gh building only supported on macOS"
else ifneq ($(wildcard $(BUILD_WORK)/gh/.build_complete),)
gh:
	@echo "Using previously built gh."
else
gh: gh-setup golang
	+$(MAKE) -C $(BUILD_WORK)/gh bin/gh manpages \
		GOARCH=arm64 \
		GOOS=darwin
	$(CP) -a $(BUILD_WORK)/gh/bin/gh $(BUILD_STAGE)/gh/usr/bin
	$(CP) -a $(BUILD_WORK)/gh/share $(BUILD_STAGE)/gh/usr
	touch $(BUILD_WORK)/gh/.build_complete
endif

gh-package: gh-stage
	# gh.mk Package Structure
	rm -rf $(BUILD_DIST)/gh
	mkdir -p $(BUILD_DIST)/gh/usr

	# gh.mk Prep gh
	cp -a $(BUILD_STAGE)/gh/usr/{bin,share} $(BUILD_DIST)/gh/usr

	# gh.mk Sign
	$(call SIGN,gh,general.xml)

	# gh.mk Make .debs
	$(call PACK,gh,DEB_GH_V)

	# gh.mk Build cleanup
	rm -rf $(BUILD_DIST)/gh

.PHONY: gh gh-package