ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS     += ipatool
IPATOOL_VERSION := 2.1.4
DEB_IPATOOL_V   ?= $(IPATOOL_VERSION)

ipatool-setup: setup
	$(call GITHUB_ARCHIVE,majd,ipatool,$(IPATOOL_VERSION),v$(IPATOOL_VERSION))
	$(call EXTRACT_TAR,ipatool-$(IPATOOL_VERSION).tar.gz,ipatool-$(IPATOOL_VERSION),ipatool)

ifneq ($(wildcard $(BUILD_WORK)/ipatool/.build_complete),)
ipatool:
	@echo "Using previously built ipatool."
else
ipatool: ipatool-setup
	cd $(BUILD_WORK)/ipatool && $(DEFAULT_GOLANG_FLAGS) go build \
		-trimpath \
		-ldflags "-X github.com/majd/ipatool/v2/cmd.version=$(IPATOOL_VERSION)" \
		-o $(BUILD_WORK)/ipatool/ipatool
	$(INSTALL) -Dm755 $(BUILD_WORK)/ipatool/ipatool -t $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

ipatool-package: ipatool-stage
	# ipatool.mk Package Structure
	rm -rf $(BUILD_DIST)/ipatool

	# ipatool.mk Prep ipatool
	cp -a $(BUILD_STAGE)/ipatool $(BUILD_DIST)

	# ipatool.mk Sign
	$(call SIGN,ipatool,general.xml)

	# ipatool.mk Make .debs
	$(call PACK,ipatool,DEB_IPATOOL_V)

	# ipatool.mk Build cleanup
	rm -rf $(BUILD_DIST)/ipatool

.PHONY: ipatool ipatool-package

endif
