ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

NPTH_VERSION := 1.6

ifneq ($(wildcard $(BUILD_WORK)/npth/.build_complete),)
npth:
	@echo "Using previously built npth."
else
npth: setup
	cd $(BUILD_WORK)/npth && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/npth
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_STAGE)/npth
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/npth/.build_complete
endif

.PHONY: npth
