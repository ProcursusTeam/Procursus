ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += chezmoi
CHEZMOI_VERSION := 2.0.10
DEB_CHEZMOI_V   ?= $(CHEZMOI_VERSION)

ifeq ($(MEMO_TARGET),iphoneos-arm64)
GO_ARGS := GOARCH=arm64 \
        GOOS=ios
else ifeq ($(MEMO_TARGET),darwin-amd64)
GO_ARGS := GOARCH=amd64 \
        GOOS=darwin
else ifneq ($(MEMO_TARGET),darwin-arm64)
GO_ARGS := GOARCH=arm64 \
        GOOS=darwin
endif

chezmoi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/twpayne/chezmoi/archive/refs/tags/v$(CHEZMOI_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(CHEZMOI_VERSION).tar.gz,chezmoi-$(CHEZMOI_VERSION),chezmoi)
	mkdir -p $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/bin


ifneq ($(wildcard $(BUILD_WORK)/chezmoi/.build_complete),)
chezmoi:
	@echo "Using previously built chezmoi."
else
chezmoi: chezmoi-setup
	cd $(BUILD_WORK)/chezmoi && go get -d -v .
	cd $(BUILD_WORK)/chezmoi && \
		CGO_ENABLED=1 \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CC=cc \
		$(GO_ARGS) \
		go build
	cp -a $(BUILD_WORK)/chezmoi/chezmoi $(BUILD_STAGE)/chezmoi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/usr/bin
	touch $(BUILD_WORK)/chezmoi/.build_complete
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
