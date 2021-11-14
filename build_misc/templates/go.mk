ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += @pkg@
@PKG@_VERSION  := @PKG_VERSION@
DEB_@PKG@_V    ?= $(@PKG@_VERSION)

@pkg@-setup: setup
	$(call GITHUB_ARCHIVE,junegunn,@pkg@,$(@PKG@_VERSION),$(@PKG@_VERSION))
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.gz,@pkg@-$(@PKG@_VERSION),@pkg@)
	mkdir -p $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup
	cd $(BUILD_WORK)/@pkg@ && $(DEFAULT_GOLANG_FLAGS) go build \
			-o $(BUILD_WORK)/@pkg@/@pkg@
	$(INSTALL) -Dm755 $(BUILD_WORK)/@pkg@/@pkg@ $(BUILD_STAGE)/@pkg@/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@
	mkdir -p $(BUILD_DIST)

	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)

	# @pkg@.mk Sign
	$(call SIGN,@pkg@,general.xml)

	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)

	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
