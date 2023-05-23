ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS     += locsim
LOCSIM_COMMIT   := 8bf4acb80bd10c121fb404341989692d4310f8f6
LOCSIM_VERSION  := 1.1.8
DEB_LOCSIM_V    ?= $(LOCSIM_VERSION)

locsim-setup: setup
	$(call GITHUB_ARCHIVE,udevsharold,locsim,$(LOCSIM_COMMIT),$(LOCSIM_COMMIT),locsim)
	$(call EXTRACT_TAR,locsim-$(LOCSIM_COMMIT).tar.gz,locsim-$(LOCSIM_COMMIT),locsim)
	mkdir -p $(BUILD_STAGE)/locsim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){,$(MEMO_ALT_PREFIX)}/bin

ifneq ($(wildcard $(BUILD_WORK)/locsim/.build_complete),)
locsim:
	@echo "Using previously built locsim."
else
locsim: locsim-setup
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_WORK)/locsim/{main,LSMGPXParserDelegate}.m \
		-o $(BUILD_STAGE)/locsim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/locsim \
		-fobjc-arc -framework Foundation -framework CoreLocation
	$(call AFTER_BUILD)
endif

locsim-package: locsim-stage
	# locsim.mk Package Structure
	rm -rf $(BUILD_DIST)/locsim

	# locsim.mk Prep locsim
	cp -a $(BUILD_STAGE)/locsim $(BUILD_DIST)

	# locsim.mk Sign
	$(call SIGN,locsim,locsim.xml)

	# locsim.mk Make .debs
	$(call PACK,locsim,DEB_LOCSIM_V)

	# locsim.mk Build cleanup
	rm -rf $(BUILD_DIST)/locsim

.PHONY: locsim locsim-package

endif
