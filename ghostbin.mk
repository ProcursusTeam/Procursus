ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += ghostbin
GHOSTBIN_COMMIT   := 0e0a3b72c3379e51bf03fe676af3a74a01239a47
GHOSTBIN_VERSION  := 1.0+git20201225.$(shell echo $(GHOSTBIN_COMMIT) | cut -c -7)
DEB_GHOSTBIN_V    ?= $(GHOSTBIN_VERSION)-1

ghostbin-setup: setup
	$(call GITHUB_ARCHIVE,DHowett,spectre,v$(GHOSTBIN_COMMIT),$(GHOSTBIN_COMMIT),ghostbin)
	$(call EXTRACT_TAR,ghostbin-v$(GHOSTBIN_COMMIT).tar.gz,spectre-$(GHOSTBIN_COMMIT),ghostbin)
	$(SED) -i '/account creation has been disabled/,+3d' $(BUILD_WORK)/ghostbin/auth.go

ifneq ($(wildcard $(BUILD_WORK)/ghostbin/.build_complete),)
ghostbin:
	@echo "Using previously built ghostbin."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
ghostbin: ghostbin-setup
else
ghostbin: ghostbin-setup libiosexec
endif
	+cd $(BUILD_WORK)/ghostbin && \
		go mod download && \
		$(DEFAULT_GOLANG_FLAGS) \
		go build
	mkdir -p $(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX){/Library/LaunchDaemons,$(MEMO_SUB_PREFIX)/{libexec/ghostbin,bin}}
	cp -a $(BUILD_WORK)/ghostbin/{ghostbin,ghosts.yml,templates,languages.yml,public} $(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ghostbin
	cp -a $(BUILD_MISC)/ghostbin/ghostbin-wrapper $(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ghostbin
	cp -a $(BUILD_MISC)/ghostbin/net.howett.ghostbin.plist $(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX)/Library/LaunchDaemons

	for file in $(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX)/Library/LaunchDaemons/* \
		$(BUILD_STAGE)/ghostbin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
			$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $$file; \
			$(SED) -i 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $$file; \
	done

	touch $(BUILD_WORK)/ghostbin/.build_complete
endif

ghostbin-package: ghostbin-stage
	# ghostbin.mk Package Structure
	rm -rf $(BUILD_DIST)/ghostbin

	# ghostbin.mk Prep ghostbin
	cp -a $(BUILD_STAGE)/ghostbin $(BUILD_DIST)

	# ghostbin.mk Sign
	$(call SIGN,ghostbin,general.xml)

	# ghostbin.mk Make .debs
	$(call PACK,ghostbin,DEB_GHOSTBIN_V)

	# ghostbin.mk Build cleanup
	rm -rf $(BUILD_DIST)/ghostbin

.PHONY: ghostbin ghostbin-package
