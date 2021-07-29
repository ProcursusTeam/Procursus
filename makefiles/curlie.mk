ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += curlie
CURLIE_VERSION  := 1.6.0
DEB_CURLIE_V    ?= $(CURLIE_VERSION)

curlie-setup: setup
	$(call GITHUB_ARCHIVE,rs,curlie,$(CURLIE_VERSION),v$(CURLIE_VERSION))
	$(call EXTRACT_TAR,curlie-$(CURLIE_VERSION).tar.gz,curlie-$(CURLIE_VERSION),curlie)

ifneq ($(wildcard $(BUILD_WORK)/curlie/.build_complete),)
curlie:
	@echo "Using previously built curlie."
else
curlie: curlie-setup
	cd $(BUILD_WORK)/curlie; $(DEFAULT_GOLANG_FLAGS) go build \
		-o release/bin/curlie \
		--ldflags="-s -w -X main.version=$(DEB_CURLIE_V) -X main.date=$(shell date -u +%Y%m%d)"
	$(INSTALL) -Dm755 $(BUILD_WORK)/curlie/release/bin/curlie \
		$(BUILD_STAGE)/curlie/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/curlie
	touch $(BUILD_WORK)/curlie/.build_complete
endif

curlie-package: curlie-stage
	# curlie.mk Package Structure
	rm -rf $(BUILD_DIST)/curlie
	cp -a $(BUILD_STAGE)/curlie $(BUILD_DIST)

	# curlie.mk Sign
	$(call SIGN,curlie,general.xml)

	# curlie.mk Make .debs
	$(call PACK,curlie,DEB_CURLIE_V)

	# curlie.mk Build Cleanup
	rm -rf $(BUILD_DIST)/curlie

.PHONY: curlie curlie-package
