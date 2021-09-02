ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += lsd
LSD_VERSION := 0.20.1
DEB_LSD_V   ?= $(LSD_VERSION)

lsd-setup: setup
	$(call GITHUB_ARCHIVE,Peltoche,lsd,$(LSD_VERSION),$(LSD_VERSION))
	$(call EXTRACT_TAR,lsd-$(LSD_VERSION).tar.gz,lsd-$(LSD_VERSION),lsd)

ifneq ($(wildcard $(BUILD_WORK)/lsd/.build_complete),)
lsd:
	@echo "Using previously built lsd."
else
lsd: lsd-setup
	# Use Lucy's fork of rust-users w/ iOS support
	sed -i 's|users = "0.11.*"|users = {git = "https://github.com/Absolucy/rust-users", branch = "ios"}|g' \
		$(BUILD_WORK)/lsd/Cargo.toml
	cd $(BUILD_WORK)/lsd; $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/lsd/target/$(RUST_TARGET)/release/lsd \
		$(BUILD_STAGE)/lsd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsd
	$(call AFTER_BUILD)
endif

lsd-package: lsd-stage
	# lsd.mk Package Structure
	rm -rf $(BUILD_DIST)/lsd
	cp -a $(BUILD_STAGE)/lsd $(BUILD_DIST)

	# lsd.mk Sign
	$(call SIGN,lsd,general.xml)

	# lsd.mk Make .debs
	$(call PACK,lsd,DEB_LSD_V)

	# lsd.mk Build Cleanup
	rm -rf $(BUILD_DIST)/lsd

.PHONY: lsd lsd-package
