ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += neofetch
DOWNLOAD         += https://github.com/dylanaraps/neofetch/archive/$(NEOFETCH_VERSION).tar.gz
NEOFETCH_VERSION := 7.0.0
DEB_NEOFETCH_V   ?= $(NEOFETCH_VERSION)

neofetch-setup: setup
	$(call EXTRACT_TAR,$(NEOFETCH_VERSION).tar.gz,neofetch-$(NEOFETCH_VERSION),neofetch)

ifneq ($(wildcard $(BUILD_WORK)/neofetch/.build_complete),)
neofetch:
	@echo "Using previously built neofetch."
else
neofetch: neofetch-setup
	+$(MAKE) -C $(BUILD_WORK)/neofetch install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/neofetch
	touch $(BUILD_WORK)/neofetch/.build_complete
endif

neofetch-package: neofetch-stage
	# neofetch.mk Package Structure
	rm -rf $(BUILD_DIST)/neofetch
	
	# neofetch.mk Prep neofetch
	$(FAKEROOT) cp -a $(BUILD_STAGE)/neofetch $(BUILD_DIST)
	
	# neofetch.mk Make .debs
	$(call PACK,neofetch,DEB_NEOFETCH_V)
	
	# neofetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/neofetch

.PHONY: neofetch neofetch-package
