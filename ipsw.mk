ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ipsw
IPSW_VERSION  := 3.0.41
DEB_IPSW_V    ?= $(IPSW_VERSION)

ipsw-setup: setup
	$(call GITHUB_ARCHIVE,blacktop,ipsw,v$(IPSW_VERSION),v$(IPSW_VERSION))
	$(call EXTRACT_TAR,ipsw-v$(IPSW_VERSION).tar.gz,ipsw-$(IPSW_VERSION),ipsw)

ifneq ($(wildcard $(BUILD_WORK)/ipsw/.build_complete),)
ipsw:
	@echo "Using previously built ipsw."
else
ipsw: ipsw-setup
	cd $(BUILD_WORK)/ipsw && $(DEFAULT_GOLANG_FLAGS) go build \
		-o build/dist/ipsw \
		-ldflags "-s -w -X github.com/blacktop/ipsw/cmd/ipsw/cmd.AppVersion=$(IPSW_VERSION) -X github.com/blacktop/ipsw/cmd/ipsw/cmd.AppBuildTime==$(shell date -u +%Y%m%d)" \
		./cmd/ipsw
	$(INSTALL) -Dm755 $(BUILD_WORK)/ipsw/build/dist/ipsw $(BUILD_STAGE)/ipsw/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/ipsw
	touch $(BUILD_WORK)/ipsw/.build_complete
endif

ipsw-package: ipsw-stage
	# ipsw.mk Package Structure
	rm -rf $(BUILD_DIST)/ipsw

	# ipsw.mk Prep ipsw
	cp -a $(BUILD_STAGE)/ipsw $(BUILD_DIST)

	# ipsw.mk Sign
	$(call SIGN,ipsw,general.xml)

	# ipsw.mk Make .debs
	$(call PACK,ipsw,DEB_IPSW_V)

	# ipsw.mk Build cleanup
	rm -rf $(BUILD_DIST)/ipsw

.PHONY: ipsw ipsw-package
