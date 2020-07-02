ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS += rust
RUST_VERSION := 1.45.0-nightly
DEB_RUST_V   ?= $(RUST_VERSION)

ifeq ($(MEMO_TARGET),iphoneos-arm64)
RUST_TARGET := aarch64-apple-ios
else ifeq ($(MEMO_TARGET),iphoneos-arm)
RUST_TARGET := armv7-apple-ios
endif

# This needs ccache extra to build.

rust-setup: setup
	if [ ! -d "$(BUILD_WORK)/rust" ]; then \
		git clone https://github.com/rust-lang/rust $(BUILD_WORK)/rust; \
		cd "$(BUILD_WORK)/rust"; \
		git fetch origin; \
		git reset --hard origin/master; \
		git checkout HEAD .; \
	fi
	# Change the above mess when the necessary iOS changes are added to upstream.

	$(call DO_PATCH,rust,rust,-p1)
	
	mkdir -p "$(BUILD_WORK)/rust/build"
	mkdir -p "$(BUILD_STAGE)/rust"
	cp -f "$(BUILD_INFO)/rust_config.toml" "$(BUILD_WORK)/rust/config.toml"

	$(SED) -i 's|PROCURSUS_BUILD_DIR|$(BUILD_WORK)/rust/build|g' "$(BUILD_WORK)/rust/config.toml"
	$(SED) -i 's|PROCURSUS_TARGET|$(RUST_TARGET)|g' "$(BUILD_WORK)/rust/config.toml"
	$(SED) -i 's|PROCURSUS_INSTALL_PREFIX|$(BUILD_STAGE)/rust/usr|g' "$(BUILD_WORK)/rust/config.toml"

ifneq ($(wildcard $(BUILD_WORK)/rust/.build_complete),)
rust:
	@echo "Using previously built rust."
else
rust: rust-setup openssl curl
	mv $(BUILD_BASE)/usr/include/stdlib.h $(BUILD_BASE)/usr/include/stdlib.h.old
	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; \
		cd "$(BUILD_WORK)/rust"; \
		export IPHONEOS_DEPLOYMENT_TARGET=10.0 \
		AARCH64_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)/usr"; \
		ARMV7_APPLE_IOS_OPENSSL_DIR="$(BUILD_BASE)/usr"; \
		./x.py build; \
		./x.py install
	mv $(BUILD_BASE)/usr/include/stdlib.h.old $(BUILD_BASE)/usr/include/stdlib.h
	touch $(BUILD_WORK)/rust/.build_complete
endif

rust-package:
