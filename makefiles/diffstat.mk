ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += diffstat
DIFFSTAT_VERSION := 1.64
DEB_DIFFSTAT_V   ?= $(DIFFSTAT_VERSION)

diffstat-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://invisible-mirror.net/archives/diffstat/diffstat-$(DIFFSTAT_VERSION).tgz{$(comma).asc})
	$(call PGP_VERIFY,diffstat-$(DIFFSTAT_VERSION).tgz,asc)
	$(call EXTRACT_TAR,diffstat-$(DIFFSTAT_VERSION).tgz,diffstat-$(DIFFSTAT_VERSION),diffstat)

ifneq ($(wildcard $(BUILD_WORK)/diffstat/.build_complete),)
diffstat:
	@echo "Using previously built diffstat."
else
diffstat: diffstat-setup
	cd $(BUILD_WORK)/diffstat && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/diffstat
	+$(MAKE) -C $(BUILD_WORK)/diffstat install \
		DESTDIR=$(BUILD_STAGE)/diffstat
	$(call AFTER_BUILD)
endif

diffstat-package: diffstat-stage
	# diffstat.mk Package Structure
	rm -rf $(BUILD_DIST)/diffstat

	# diffstat.mk Prep diffstat
	cp -a $(BUILD_STAGE)/diffstat $(BUILD_DIST)

	# diffstat.mk Sign
	$(call SIGN,diffstat,general.xml)

	# diffstat.mk Make .debs
	$(call PACK,diffstat,DEB_DIFFSTAT_V)

	# diffstat.mk Build cleanup
	rm -rf $(BUILD_DIST)/diffstat

.PHONY: diffstat diffstat-package
