ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += fzf
FZF_VERSION  := 0.24.4
DEB_FZF_V    ?= $(FZF_VERSION)

fzf-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/fzf-$(FZF_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/fzf-$(FZF_VERSION).tar.gz \
			https://github.com/junegunn/fzf/archive/$(FZF_VERSION).tar.gz
	$(call EXTRACT_TAR,fzf-$(FZF_VERSION).tar.gz,fzf-$(FZF_VERSION),fzf)
	mkdir -p $(BUILD_STAGE)/fzf/usr/share

ifneq ($(ARCHES),arm64)
fzf:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(wildcard $(BUILD_WORK)/fzf/.build_complete),)
fzf:
	@echo "Using previously built fzf."
else
fzf: fzf-setup
	+$(MAKE) -C $(BUILD_WORK)/fzf bin/fzf \
		FZF_VERSION="$(FZF_VERSION)" \
		FZF_REVISION="Procursus" \
		BINARY="fzf-darwin_arm8" \
		GOARCH=arm64 \
		GOOS=darwin \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CGO_ENABLED=1 \
		CC="$(CC)"
	$(CP) -a $(BUILD_WORK)/fzf/bin $(BUILD_STAGE)/fzf/usr
	$(CP) -a $(BUILD_WORK)/fzf/man $(BUILD_STAGE)/fzf/usr/share
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
