ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += nekofetch
NEKOFETCH_VERSION := 1.4
DEB_NEKOFETCH_V   ?= $(NEKOFETCH_VERSION)

nekofetch-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/proprdev/nekofetch/archive/refs/tags/v$(NEKOFETCH_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(NEKOFETCH_VERSION).tar.gz,nekofetch-$(NEKOFETCH_VERSION),nekofetch)

ifneq ($(wildcard $(BUILD_WORK)/nekofetch/.build_complete),)
nekofetch:
	@echo "Using previously built nekofetch."
else
nekofetch: nekofetch-setup
	+$(MAKE) -C $(BUILD_WORK)/nekofetch install \
		PREFIX=$(BUILD_STAGE)/nekofetch$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	# TODO: Separate DESTDIR from PREFIX when fix is added upstream
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
