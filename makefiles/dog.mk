ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += dog
DOG_VERSION  := 0.1.0
DEB_DOG_V    ?= $(DOG_VERSION)

dog-setup: setup
	$(call GITHUB_ARCHIVE,ogham,dog,$(DOG_VERSION),v$(DOG_VERSION))
	$(call EXTRACT_TAR,dog-$(DOG_VERSION).tar.gz,dog-$(DOG_VERSION),dog)

ifneq ($(wildcard $(BUILD_WORK)/dog/.build_complete),)
dog:
	@echo "Using previously built dog."
else
dog: dog-setup
	cd $(BUILD_WORK)/dog && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/dog/target/$(RUST_TARGET)/release/dog $(BUILD_STAGE)/dog/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dog
	$(call AFTER_BUILD)
endif

dog-package: dog-stage
	# dog.mk Package Structure
	rm -rf $(BUILD_DIST)/dog

	# dog.mk Prep dog
	cp -a $(BUILD_STAGE)/dog $(BUILD_DIST)

	# dog.mk Sign
	$(call SIGN,dog,general.xml)

	# dog.mk Make .debs
	$(call PACK,dog,DEB_DOG_V)

	# dog.mk Build cleanup
	rm -rf $(BUILD_DIST)/dog

.PHONY: dog dog-package
