ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET))

SUBPROJECTS               += procursus-headers
PROCURSUS_HEADERS_VERSION := 2021.11.11
DEB_PROCURSUS_HEADERS_V   ?= $(PROCURSUS_HEADERS_VERSION)

procursus-headers-setup: setup

ifneq ($(wildcard $(BUILD_WORK)/procursus-headers/.build_complete),)
procursus-headers:
	@echo "Using previously built procursus-headers."
else
procursus-headers: procursus-headers-setup
	$(MAKE) setup BUILD_BASE=$(BUILD_STAGE)/procursus-headers
	rm -rf $(BUILD_STAGE)/procursus-headers/$(MEMO_PREFIX){System,Library,$(MEMO_SUB_PREFIX)/{include/libiosexec.h,local,lib/{libiosexec*.tbd,pkgconfig/libxml-2.0.pc}}}
	$(call AFTER_BUILD)
endif

procursus-headers-package: procursus-headers-stage
	# procursus-headers.mk Package Structure
	rm -rf $(BUILD_DIST)/procursus-headers
	
	# procursus-headers.mk Prep procursus-headers
	cp -a $(BUILD_STAGE)/procursus-headers $(BUILD_DIST)
	
	# procursus-headers.mk Make .debs
	$(call PACK,procursus-headers,DEB_PROCURSUS_HEADERS_V)
	
	# procursus-headers.mk Build cleanup
	rm -rf $(BUILD_DIST)/procursus-headers

.PHONY: procursus-headers procursus-headers-package
endif
