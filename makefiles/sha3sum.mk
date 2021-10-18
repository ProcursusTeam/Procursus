ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += sha3sum
SHA3SUM_VERSION := 1.2.1
DEB_SHA3SUM_V   ?= $(SHA3SUM_VERSION)

sha3sum-setup: setup
	$(call GITHUB_ARCHIVE,maandree,sha3sum,$(SHA3SUM_VERSION),$(SHA3SUM_VERSION))
	$(call EXTRACT_TAR,sha3sum-$(SHA3SUM_VERSION).tar.gz,sha3sum-$(SHA3SUM_VERSION),sha3sum)
	sed -i 's/ = -/+= -/g' $(BUILD_WORK)/sha3sum/config.mk
	sed -i '/PREFIX  /d' $(BUILD_WORK)/sha3sum/config.mk

ifneq ($(wildcard $(BUILD_WORK)/sha3sum/.build_complete),)
sha3sum:
	@echo "Using previously built sha3sum."
else
sha3sum: sha3sum-setup libkeccak
	$(MAKE) -C $(BUILD_WORK)/sha3sum
	+$(MAKE) -C $(BUILD_WORK)/sha3sum install \
		DESTDIR=$(BUILD_STAGE)/sha3sum \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -rf $(BUILD_STAGE)/sha3sum/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/licenses
	$(call AFTER_BUILD)
endif

sha3sum-package: sha3sum-stage
	# sha3sum.mk Package Structure
	rm -rf $(BUILD_DIST)/sha3sum
	
	# sha3sum.mk Prep sha3sum
	cp -a $(BUILD_STAGE)/sha3sum $(BUILD_DIST)
	
	# sha3sum.mk Sign
	$(call SIGN,sha3sum,general.xml)
	
	# sha3sum.mk Make .debs
	$(call PACK,sha3sum,DEB_SHA3SUM_V)
	
	# sha3sum.mk Build cleanup
	rm -rf $(BUILD_DIST)/sha3sum

.PHONY: sha3sum sha3sum-package
