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
	+$(MAKE) -C $(BUILD_WORK)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_STAGE)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/nettle/.build_complete
endif

nettle-package: nettle-stage
	# nettle.mk Package Structure
	rm -rf $(BUILD_DIST)/nettle
	mkdir -p $(BUILD_DIST)/nettle
	
	# nettle.mk Prep nettle
	$(FAKEROOT) cp -a $(BUILD_STAGE)/nettle/usr $(BUILD_DIST)/nettle
	
	# nettle.mk Sign
	$(call SIGN,nettle,general.xml)
	
	# nettle.mk Make .debs
	$(call PACK,nettle,DEB_NETTLE_V)
	
	# nettle.mk Build cleanup
	rm -rf $(BUILD_DIST)/nettle

.PHONY: nettle nettle-package
