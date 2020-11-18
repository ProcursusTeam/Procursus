ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += ripgrep
RIPGREP_VERSION := 12.1.1
DEB_RIPGREP_V   ?= $(RIPGREP_VERSION)

ripgrep-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/ripgrep-$(RIPGREP_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/ripgrep-$(RIPGREP_VERSION).tar.gz https://github.com/BurntSushi/ripgrep/archive/$(RIPGREP_VERSION).tar.gz
	$(call EXTRACT_TAR,ripgrep-$(RIPGREP_VERSION).tar.gz,ripgrep-$(RIPGREP_VERSION),ripgrep)

ifneq ($(wildcard $(BUILD_WORK)/ripgrep/.build_complete),)
ripgrep:
	@echo "Using previously built ripgrep."
else
ripgrep: ripgrep-setup
	cd $(BUILD_WORK)/ripgrep && SDKROOT="$(TARGET_SYSROOT)" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/ripgrep/target/$(RUST_TARGET)/release/rg $(BUILD_STAGE)/ripgrep/usr/bin/rg
	$(GINSTALL) -Dm644 $(BUILD_WORK)/ripgrep/complete/_rg $(BUILD_STAGE)/ripgrep/usr/share/zsh/site-functions/_rg
	$(GINSTALL) -Dm644 $(BUILD_WORK)/ripgrep/target/$(RUST_TARGET)/release/build/ripgrep-*/out/rg.1 $(BUILD_STAGE)/ripgrep/usr/share/man/man1/rg.1
	$(GINSTALL) -Dm644 $(BUILD_WORK)/ripgrep/target/$(RUST_TARGET)/release/build/ripgrep-*/out/rg.bash $(BUILD_STAGE)/ripgrep/usr/share/bash-completion/completions/rg
	touch $(BUILD_WORK)/ripgrep/.build_complete
endif

ripgrep-package: ripgrep-stage
	# ripgrep.mk Package Structure
	rm -rf $(BUILD_DIST)/ripgrep
	
	# ripgrep.mk Prep ripgrep
	cp -a $(BUILD_STAGE)/ripgrep $(BUILD_DIST)
	
	# ripgrep.mk Sign
	$(call SIGN,ripgrep,general.xml)
	
	# ripgrep.mk Make .debs
	$(call PACK,ripgrep,DEB_RIPGREP_V)
	
	# ripgrep.mk Build cleanup
	rm -rf $(BUILD_DIST)/ripgrep

.PHONY: ripgrep ripgrep-package
