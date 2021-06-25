ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += neofetch
NEOFETCH_COMMIT  := 611117f4af527de3b81bc92c74ae976e130d39e6
NEOFETCH_VERSION := 7.1.0+20210611.$(shell echo $(NEOFETCH_COMMIT) | cut -c -7) #TODO: Switch back to releases once a new version releases
DEB_NEOFETCH_V   ?= $(NEOFETCH_VERSION)

neofetch-setup: setup
	$(call GITHUB_ARCHIVE,dylanaraps,neofetch,$(NEOFETCH_COMMIT),$(NEOFETCH_COMMIT))
	$(call EXTRACT_TAR,neofetch-$(NEOFETCH_COMMIT).tar.gz,neofetch-$(NEOFETCH_COMMIT),neofetch)

ifneq ($(wildcard $(BUILD_WORK)/neofetch/.build_complete),)
neofetch:
	@echo "Using previously built neofetch."
else
neofetch: neofetch-setup
	+$(MAKE) -C $(BUILD_WORK)/neofetch install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/neofetch
	touch $(BUILD_WORK)/neofetch/.build_complete
endif

neofetch-package: neofetch-stage
	# neofetch.mk Package Structure
	rm -rf $(BUILD_DIST)/neofetch

	# neofetch.mk Prep neofetch
	cp -a $(BUILD_STAGE)/neofetch $(BUILD_DIST)

	# neofetch.mk Make .debs
	$(call PACK,neofetch,DEB_NEOFETCH_V)

	# neofetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/neofetch

.PHONY: neofetch neofetch-package
