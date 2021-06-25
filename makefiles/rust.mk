ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS += rust
RUST_VERSION := 1.46.0
DEB_RUST_V   ?= $(RUST_VERSION)

# This needs ccache extra to build.

##### THIS MAKEFILE IS CURRENTLY WIP AGAIN #####

rust-setup: setup
	$(call GITHUB_ARCHIVE,rust-lang,rust,$(RUST_VERSION),$(RUST_VERSION))
	$(call EXTRACT_TAR,rust-$(RUST_VERSION).tar.gz,rust-$(RUST_VERSION),rust)

	mkdir -p "$(BUILD_WORK)/rust/build"
	mkdir -p "$(BUILD_STAGE)/rust"
	cp -f "$(BUILD_INFO)/rust_config.toml" "$(BUILD_WORK)/rust/config.toml"

	$(SED) -i -e 's|PROCURSUS_BUILD_DIR|$(BUILD_WORK)/rust/build|g' -e 's|PROCURSUS_TARGET|$(RUST_TARGET)|g' -e 's|PROCURSUS_INSTALL_PREFIX|$(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' "$(BUILD_WORK)/rust/config.toml"
	#$(SED) -i -e 's/"LLVM_ENABLE_ZLIB", "OFF"/"LLVM_ENABLE_ZLIB", "ON"/' -e 's|"CMAKE_OSX_SYSROOT", "/"|"CMAKE_OSX_SYSROOT", "$(TARGET_SYSROOT)"|' "$(BUILD_WORK)/rust/src/bootstrap/native.rs"

ifneq ($(wildcard $(BUILD_WORK)/rust/.build_complete),)
rust:
	@echo "Using previously built rust."
else
rust: rust-setup openssl curl
	mv $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h.old
	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; \
		cd "$(BUILD_WORK)/rust"; \
		export MACOSX_DEPLOYMENT_TARGET=10.13 \
		IPHONEOS_DEPLOYMENT_TARGET=10.0 \
		AARCH64_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"; \
		ARMV7_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"; \
		./x.py build; \
		./x.py install
	mv $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h.old $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/stdlib.h
	rm -rf $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/doc,etc}
	rm -rf $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/rustlib/{src,manifest-*,components,install.log,uninstall.sh,rust-installer-version}
	rm -rf $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/rustlib/*/analysis
	touch $(BUILD_WORK)/rust/.build_complete
endif

rust-package: rust
	# rust.mk Package Structure
	rm -rf $(BUILD_DIST)/{rust{,-toolchain},cargo}
	mkdir -p $(BUILD_DIST)/{rust,cargo}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	mkdir -p $(BUILD_DIST)/rust-toolchain/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rust.mk Prep rust
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{rust*,clippy-driver} $(BUILD_DIST)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/rust* $(BUILD_DIST)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# rust.mk Prep cargo
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cargo* $(BUILD_DIST)/cargo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh $(BUILD_DIST)/cargo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/cargo* $(BUILD_DIST)/cargo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# rust.mk Prep rust-toolchain
	cp -a $(BUILD_STAGE)/rust/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/rust-toolchain/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rust.mk Sign
	$(call SIGN,rust,general.xml)
	$(call SIGN,cargo,general.xml)
	$(call SIGN,rust-toolchain,general.xml)

	# rust.mk Make .debs
	$(call PACK,rust,DEB_RUST_V)
	$(call PACK,cargo,DEB_RUST_V)
	$(call PACK,rust-toolchain,DEB_RUST_V)

	# rust.mk Build cleanup
	rm -rf $(BUILD_DIST)/{cargo,rust{,-toolchain}}

.PHONY: rust rust-package
