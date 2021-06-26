ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += bottom
BOTTOM_VERSION := 1.2.0
DEB_BOTTOM_V   ?= $(BOTTOM_VERSION)

bottom-setup: setup
	$(call GITHUB_ARCHIVE,bottom-software-foundation,bottom-rs,$(BOTTOM_VERSION),need_top,bottom)
	$(call EXTRACT_TAR,bottom-$(BOTTOM_VERSION).tar.gz,bottom-rs-need_top,bottom)

ifneq ($(wildcard $(BUILD_WORK)/bottom/.build_complete),)
bottom:
	@echo "Using previously built bottom."
else
bottom: bottom-setup
	cd $(BUILD_WORK)/bottom && SDKROOT="$(TARGET_SYSROOT)" cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/bottom/target/$(RUST_TARGET)/release/bottomify \
		$(BUILD_STAGE)/bottom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bottomify
	touch $(BUILD_WORK)/bottom/.build_complete
endif

bottom-package: bottom-stage
	# bottom.mk Package Structure
	mkdir -p $(BUILD_DIST)/bottom
	cp -a $(BUILD_STAGE)/bottom $(BUILD_DIST)

	# bottom.mk Sign
	$(call SIGN,bottom,general.xml)

	# bottom.mk Make .debs
	$(call PACK,bottom,DEB_BOTTOM_V)

	# bottom.mk Build cleanup
	rm -rf $(BUILD_DIST)/bottom

.PHONY: bottom bottom-package
