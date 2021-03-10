ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += neofetch
NEOFETCH_VERSION := 7.1.0
DEB_NEOFETCH_V   ?= $(NEOFETCH_VERSION)

neofetch-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/dylanaraps/neofetch/archive/$(NEOFETCH_VERSION).tar.gz
	$(call EXTRACT_TAR,$(NEOFETCH_VERSION).tar.gz,neofetch-$(NEOFETCH_VERSION),neofetch)

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
