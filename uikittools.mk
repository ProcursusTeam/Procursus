ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS      += uikittools
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS        += uikittools
endif # ($(MEMO_TARGET),darwin-\*)
UIKITTOOLS_COMMIT  := 5612b677b09dc8851f2c830a26d70183c10045a2
UIKITTOOLS_VERSION := 2.0.4
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

uikittools-setup: setup
	$(call GITHUB_ARCHIVE,Diatrus,uikittools-ng,$(UIKITTOOLS_COMMIT),$(UIKITTOOLS_COMMIT))
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_COMMIT).tar.gz,uikittools-ng-$(UIKITTOOLS_COMMIT),uikittools)

ifneq ($(wildcard $(BUILD_WORK)/uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: uikittools-setup
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		CC=$(CC) \
		STRIP=$(STRIP) \
		CFLAGS="$(CFLAGS)"
	mkdir -p $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in $(BUILD_WORK)/uikittools/*; do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			cp $$bin $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin ; \
		fi \
	done
	touch $(BUILD_WORK)/uikittools/.build_complete
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools
	mkdir -p $(BUILD_DIST)/uikittools
	
	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/uikittools
	
	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)
	
	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools

.PHONY: uikittools uikittools-package
