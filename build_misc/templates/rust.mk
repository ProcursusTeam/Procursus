ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += @pkg@
@PKG@_VERSION  := @PKG_VERSION@
DEB_@PKG@_V    ?= $(@PKG@_VERSION)

@pkg@-setup: setup
@download@
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.@compression@,@pkg@-$(@PKG@_VERSION),@pkg@)

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup
	cd $(BUILD_WORK)/@pkg@ && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--all-features \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/@pkg@/target/$(RUST_TARGET)/release/@pkg@ $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/@pkg@
	$(call AFTER_BUILD)
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@

	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)

	# @pkg@.mk Sign
	$(call SIGN,@pkg@,general.xml)

	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)

	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
