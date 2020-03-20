ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DIFFUTILS_VERSION := 3.7

ifneq ($(wildcard $(BUILD_WORK)/diffutils/.build_complete),)
diffutils:
	@echo "Using previously built diffutils."
else
diffutils: setup
	cd $(BUILD_WORK)/diffutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	$(MAKE) -C $(BUILD_WORK)/diffutils
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/diffutils install \
		DESTDIR=$(BUILD_STAGE)/diffutils
	touch $(BUILD_WORK)/diffutils/.build_complete
endif

.PHONY: diffutils diffutils-stage
