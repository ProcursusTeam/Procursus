ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += shc
SHC_VERSION := 4.0.3
DEB_SHC_V   ?= $(SHC_VERSION)

shc-setup: setup
	$(call GITHUB_ARCHIVE,neurobin,shc,$(SHC_VERSION),$(SHC_VERSION))
	$(call EXTRACT_TAR,shc-$(SHC_VERSION).tar.gz,shc-$(SHC_VERSION),shc)


ifneq ($(wildcard $(BUILD_WORK)/shc/.build_complete),)
shc:
	@echo "Using previously built shc."
else
shc: shc-setup
	cd $(BUILD_WORK)/shc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
			ac_cv_func_malloc_0_nonnull=yes \
			ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/shc
	+$(MAKE) -C $(BUILD_WORK)/shc install \
		DESTDIR=$(BUILD_STAGE)/shc
	touch $(BUILD_WORK)/shc/.build_complete
endif

shc-package: shc-stage
	# shc.mk Package Structure
	rm -rf $(BUILD_DIST)/shc
	mkdir -p $(BUILD_DIST)/shc
	
	# shc.mk Prep shc
	cp -a $(BUILD_STAGE)/shc $(BUILD_DIST)
	
	# shc.mk Sign
	$(call SIGN,shc,general.xml)
	
	# shc.mk Make .debs
	$(call PACK,shc,DEB_SHC_V)
	
	# shc.mk Build cleanup
	rm -rf $(BUILD_DIST)/shc

.PHONY: shc shc-package

