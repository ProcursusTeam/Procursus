ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += haydenfetch
HAYDENFETCH_VERSION := 1.0-2
DEB_HAYDENFETCH_V   ?= $(HAYDENFETCH_VERSION)

haydenfetch-setup: setup
	$(call GITHUB_ARCHIVE,asdfugil,haydenfetch,$(HAYDENFETCH_VERSION),v$(HAYDENFETCH_VERSION))
	$(call EXTRACT_TAR,v$(HAYDENFETCH_VERSION).tar.gz,haydenfetch-$(HAYDENFETCH_VERSION),haydenfetch)

ifneq ($(wildcard $(BUILD_WORK)/haydenfetch/.build_complete),)
haydenfetch:
	@echo "Using previously built haydenfetch."
else
haydenfetch: haydenfetch-setup
	+$(MAKE) -C $(BUILD_WORK)/haydenfetch install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/haydenfetch
	touch $(BUILD_WORK)/haydenfetch/.build_complete
endif

haydenfetch-package: haydenfetch-stage
	# haydenfetch.mk Package Structure
	rm -rf $(BUILD_DIST)/haydenfetch
	
	# haydenfetch.mk Prep haydenfetch
	cp -a $(BUILD_STAGE)/haydenfetch $(BUILD_DIST)
	
	# haydenfetch.mk Make .debs
	$(call PACK,haydenfetch,DEB_HAYDENFETCH_V)
	
	# haydenfetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/haydenfetch

.PHONY: haydenfetch haydenfetch-package
