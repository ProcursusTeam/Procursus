ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

NETTLE_VERSION := 3.5.1
DEB_NETTLE_V   ?= $(NETTLE_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/nettle/.build_complete),)
nettle:
	@echo "Using previously built nettle."
else
nettle: setup libgmp10
	cd $(BUILD_WORK)/nettle && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/nettle
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_STAGE)/nettle
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/nettle/.build_complete
endif

.PHONY: nettle
