ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += fd
FD_VERSION  := 8.6.0
DEB_FD_V    ?= $(FD_VERSION)

fd-setup: setup
	$(call GITHUB_ARCHIVE,sharkdp,fd,$(FD_VERSION),v$(FD_VERSION))
	$(call EXTRACT_TAR,fd-$(FD_VERSION).tar.gz,fd-$(FD_VERSION),fd)
	sed -i 's+users = "0.11.0"+users = {git = "https://github.com/ogham/rust-users", rev = "5208452"}+g' \
		$(BUILD_WORK)/fd/Cargo.toml
	sed -i 's|(target_os = "macos")|(target_vendor = "apple")|' \
		$(BUILD_WORK)/fd/Cargo.toml $(BUILD_WORK)/fd/src/main.rs $(BUILD_WORK)/fd/src/walk.rs

ifneq ($(wildcard $(BUILD_WORK)/fd/.build_complete),)
fd:
	@echo "Using previously built fd."
else
fd: fd-setup
	cd $(BUILD_WORK)/fd && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/fd/target/$(RUST_TARGET)/release/fd $(BUILD_STAGE)/fd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/fd
	$(INSTALL) -Dm644 $(BUILD_WORK)/fd/doc/fd.1 $(BUILD_STAGE)/fd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/fd.1
	$(call AFTER_BUILD)
endif

fd-package: fd-stage
	# fd.mk Package Structure
	rm -rf $(BUILD_DIST)/fd

	# fd.mk Prep fd
	cp -a $(BUILD_STAGE)/fd $(BUILD_DIST)

	# fd.mk Sign
	$(call SIGN,fd,general.xml)

	# fd.mk Make .debs
	$(call PACK,fd,DEB_FD_V)

	# fd.mk Build cleanup
	rm -rf $(BUILD_DIST)/fd

.PHONY: fd fd-package
