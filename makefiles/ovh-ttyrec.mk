ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += ovh-ttyrec
OVH_TTYREC_VERSION := 1.1.6.7
DEB_OVH_TTYREC_V   ?= $(OVH_TTYREC_VERSION)

ovh-ttyrec-setup: setup
	$(call GITHUB_ARCHIVE,ovh,ovh-ttyrec,$(OVH_TTYREC_VERSION),v$(OVH_TTYREC_VERSION))
	$(call EXTRACT_TAR,ovh-ttyrec-$(OVH_TTYREC_VERSION).tar.gz,ovh-ttyrec-$(OVH_TTYREC_VERSION),ovh-ttyrec)
	sed -i '1 i\#define SIGWINCH 28' $(BUILD_WORK)/ovh-ttyrec/ttyrec.c

ifneq ($(wildcard $(BUILD_WORK)/ovh-ttyrec/.build_complete),)
ovh-ttyrec:
	@echo "Using previously built ovh-ttyrec."
else
ovh-ttyrec: ovh-ttyrec-setup
	cd $(BUILD_WORK)/ovh-ttyrec && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/ovh-ttyrec
	+$(MAKE) -C $(BUILD_WORK)/ovh-ttyrec install \
		DESTDIR=$(BUILD_STAGE)/ovh-ttyrec
	$(call AFTER_BUILD)
endif

ovh-ttyrec-package: ovh-ttyrec-stage
	# ovh-ttyrec.mk Package Structure
	rm -rf $(BUILD_DIST)/ovh-ttyrec
	
	# ovh-ttyrec.mk Prep ovh-ttyrec
	cp -a $(BUILD_STAGE)/ovh-ttyrec $(BUILD_DIST)
	
	# ovh-ttyrec.mk Sign
	$(call SIGN,ovh-ttyrec,general.xml)
	
	# ovh-ttyrec.mk Make .debs
	$(call PACK,ovh-ttyrec,DEB_OVH_TTYREC_V)
	
	# ovh-ttyrec.mk Build cleanup
	rm -rf $(BUILD_DIST)/ovh-ttyrec

.PHONY: ovh-ttyrec ovh-ttyrec-package
