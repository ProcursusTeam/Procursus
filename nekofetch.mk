ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += nekofetch
NEKOFETCH_COMMIT  := baac62446842daa585d625a5ee0a097f2733130d
NEKOFETCH_VERSION := 1.4+git20210404.$(shell echo $(NEKOFETCH_COMMIT) | cut -c -7)
DEB_NEKOFETCH_V   ?= $(NEKOFETCH_VERSION)

nekofetch-setup: setup
	$(call GITHUB_ARCHIVE,proprdev,nekofetch,$(NEKOFETCH_COMMIT),$(NEKOFETCH_COMMIT))
	$(call EXTRACT_TAR,nekofetch-$(NEKOFETCH_COMMIT).tar.gz,nekofetch-$(NEKOFETCH_COMMIT),nekofetch)

ifneq ($(wildcard $(BUILD_WORK)/nekofetch/.build_complete),)
nekofetch:
	@echo "Using previously built nekofetch."
else
nekofetch: nekofetch-setup
	+$(MAKE) -C $(BUILD_WORK)/nekofetch install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/nekofetch
	touch $(BUILD_WORK)/nekofetch/.build_complete
endif

nekofetch-package: nekofetch-stage
	# nekofetch.mk Package Structure
	rm -rf $(BUILD_DIST)/nekofetch

	# nekofetch.mk Prep nekofetch
	cp -a $(BUILD_STAGE)/nekofetch $(BUILD_DIST)

	# nekofetch.mk Make .debs
	$(call PACK,nekofetch,DEB_NEKOFETCH_V)

	# nekofetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/nekofetch

.PHONY: nekofetch nekofetch-package
