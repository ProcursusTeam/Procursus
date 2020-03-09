ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

diffutils: setup
	cd $(BUILD_WORK)/diffutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	$(MAKE) -C $(BUILD_WORK)/diffutils
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/diffutils install \
		DESTDIR=$(BUILD_STAGE)/diffutils

.PHONY: diffutils diffutils-stage
