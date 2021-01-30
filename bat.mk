ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += bat
BAT_VERSION := 0.17.1
DEB_BAT_V   ?= $(BAT_VERSION)

bat-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/bat-$(BAT_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/bat-$(BAT_VERSION).tar.gz https://github.com/sharkdp/bat/archive/v$(BAT_VERSION).tar.gz
	$(call EXTRACT_TAR,bat-$(BAT_VERSION).tar.gz,bat-$(BAT_VERSION),bat)

ifneq ($(wildcard $(BUILD_WORK)/bat/.build_complete),)
bat:
	@echo "Using previously built bat."
else
bat: bat-setup libgit2
	cd $(BUILD_WORK)/bat && cargo update
	cd $(BUILD_WORK)/bat && SDKROOT="$(TARGET_SYSROOT)" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/bat/target/$(RUST_TARGET)/release/bat $(BUILD_STAGE)/bat/usr/bin/bat
	$(GINSTALL) -Dm644 $(BUILD_WORK)/bat/target/$(RUST_TARGET)/release/build/bat-*/out/assets/manual/bat.1 \
		$(BUILD_STAGE)/bat/usr/share/man/man1/bat.1
	$(GINSTALL) -Dm644 $(BUILD_WORK)/bat/target/$(RUST_TARGET)/release/build/bat-*/out/assets/completions/bat.zsh \
		$(BUILD_STAGE)/bat/usr/share/zsh/site-functions/_bat
	touch $(BUILD_WORK)/bat/.build_complete
endif

bat-package: bat-stage
	# bat.mk Package Structure
	rm -rf $(BUILD_DIST)/bat
	
	# bat.mk Prep bat
	cp -a $(BUILD_STAGE)/bat $(BUILD_DIST)
	
	# bat.mk Sign
	$(call SIGN,bat,general.xml)
	
	# bat.mk Make .debs
	$(call PACK,bat,DEB_BAT_V)
	
	# bat.mk Build cleanup
	rm -rf $(BUILD_DIST)/bat

.PHONY: bat bat-package
