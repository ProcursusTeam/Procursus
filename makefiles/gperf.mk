ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gperf
GPERF_VERSION := 3.1
DEB_GPERF_V   ?= $(GPERF_VERSION)

gperf-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://ftpmirror.gnu.org/gnu/gperf/gperf-$(GPERF_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,gperf-$(GPERF_VERSION).tar.gz)
	$(call EXTRACT_TAR,gperf-$(GPERF_VERSION).tar.gz,gperf-$(GPERF_VERSION),gperf)

ifneq ($(wildcard $(BUILD_WORK)/gperf/.build_complete),)
gperf:
	@echo "Using previously built gperf."
else
gperf: gperf-setup
	cd $(BUILD_WORK)/gperf && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/gperf
	+$(MAKE) -C $(BUILD_WORK)/gperf install \
		DESTDIR=$(BUILD_STAGE)/gperf
	$(call AFTER_BUILD)
endif

gperf-package: gperf-stage
	# gperf.mk Package Structure
	rm -rf $(BUILD_DIST)/gperf
	
	# gperf.mk Prep gperf
	cp -a $(BUILD_STAGE)/gperf $(BUILD_DIST)
	
	# gperf.mk Sign
	$(call SIGN,gperf,general.xml)
	
	# gperf.mk Make .debs
	$(call PACK,gperf,DEB_GPERF_V)
	
	# gperf.mk Build cleanup
	rm -rf $(BUILD_DIST)/gperf

.PHONY: gperf gperf-package
