ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += gh
GH_VERSION  := 1.3.0
DEB_GH_V    ?= $(GH_VERSION)

gh-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/gh-$(GH_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/gh-$(GH_VERSION).tar.gz \
			https://github.com/cli/cli/archive/v$(GH_VERSION).tar.gz
	$(call EXTRACT_TAR,gh-$(GH_VERSION).tar.gz,cli-$(GH_VERSION),gh)
	mkdir -p $(BUILD_STAGE)/gh/usr/bin

ifneq ($(MEMO_TARGET),darwin-arm64e)
	$(SED) -i 's/exe := "open"/exe := "uiopen"/' $(BUILD_WORK)/gh/pkg/browser/browser.go
endif

ifneq ($(ARCHES),arm64)
gh:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(wildcard $(BUILD_WORK)/gh/.build_complete),)
gh:
	@echo "Using previously built gh."
else
gh: gh-setup
	+$(MAKE) -C $(BUILD_WORK)/gh bin/gh \
		GOARCH=arm64 \
		GOOS=darwin \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CGO_ENABLED=1 \
		CC="$(CC)"
	+unset CC CXX CFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/gh manpages
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
