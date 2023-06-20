ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ply
PLY_COMMIT   := 663ca4754218f780059ce490798b012183e4d0b4
PLY_VERSION  := 1.0.0-$(shell echo $(PLY_COMMIT) | cut -c -7)
DEB_PLY_V    ?= $(PLY_VERSION)

ply-setup: setup
	$(call GITHUB_ARCHIVE,DHowett,go-plist,$(PLY_COMMIT),$(PLY_COMMIT),ply)
	$(call EXTRACT_TAR,ply-$(PLY_COMMIT).tar.gz,go-plist-$(PLY_COMMIT),ply)
	mkdir -p $(BUILD_STAGE)/ply/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ply/.build_complete),)
ply:
	@echo "Using previously built ply."
else
ply: ply-setup
	cd $(BUILD_WORK)/ply && $(DEFAULT_GOLANG_FLAGS) go build \
		-trimpath \
		-o $(BUILD_WORK)/ply/ply \
		$(BUILD_WORK)/ply/cmd/ply
	$(INSTALL) -Dm755 $(BUILD_WORK)/ply/ply $(BUILD_STAGE)/ply/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

ply-package: ply-stage
	# ply.mk Package Structure
	rm -rf $(BUILD_DIST)/ply

	# ply.mk Prep ply
	cp -a $(BUILD_STAGE)/ply $(BUILD_DIST)

	# ply.mk Sign
	$(call SIGN,ply,general.xml)

	# ply.mk Make .debs
	$(call PACK,ply,DEB_PLY_V)

	# ply.mk Build cleanup
	rm -rf $(BUILD_DIST)/ply

.PHONY: ply ply-package
