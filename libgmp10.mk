ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

GMP_VERSION := 6.2.0
DEB_GMP_V   ?= $(GMP_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libgmp10/.build_complete),)
libgmp10:
	@echo "Using previously built libgmp10."
else
libgmp10: setup
	cd $(BUILD_WORK)/libgmp10 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-assembly
	$(MAKE) -C $(BUILD_WORK)/libgmp10
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_STAGE)/libgmp10
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgmp10/.build_complete
endif

.PHONY: libgmp10
