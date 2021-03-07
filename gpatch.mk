ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += gpatch
GPATCH_VERSION := 2.7.6
DEB_GPATCH_V   ?= $(GPATCH_VERSION)

gpatch-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirror.its.dal.ca/gnu/patch/patch-$(GPATCH_VERSION).tar.gz
	$(call EXTRACT_TAR,patch-$(GPATCH_VERSION).tar.gz,patch-$(GPATCH_VERSION),gpatch)

ifneq ($(wildcard $(BUILD_WORK)/gpatch/.build_complete),)
gpatch:
	@echo "Using previously built gpatch."
else
gpatch: gpatch-setup
	cd $(BUILD_WORK)/gpatch && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/gpatch
	+$(MAKE) -C $(BUILD_WORK)/gpatch install \
		DESTDIR=$(BUILD_STAGE)/gpatch
	touch $(BUILD_WORK)/gpatch/.build_complete
endif

gpatch-package: gpatch-stage
	# gpatch.mk Package Structure
	rm -rf $(BUILD_DIST)/gpatch
	mkdir -p $(BUILD_DIST)/gpatch
	
	# gpatch.mk Prep gpatch
	mv $(BUILD_STAGE)/gpatch/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/patch $(BUILD_STAGE)/gpatch/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/gpatch
	cp -a $(BUILD_STAGE)/gpatch/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) $(BUILD_DIST)/gpatch
	
	# gpatch.mk Sign
	$(call SIGN,gpatch,general.xml)
	
	# gpatch.mk Make .debs
	$(call PACK,gpatch,DEB_GPATCH_V)
	
	# gpatch.mk Build cleanup
	rm -rf $(BUILD_DIST)/gpatch

.PHONY: gpatch gpatch-package
