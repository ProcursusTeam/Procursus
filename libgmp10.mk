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
	+$(MAKE) -C $(BUILD_WORK)/libgmp10
	+$(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_STAGE)/libgmp10
	+$(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgmp10/.build_complete
endif

libgmp10-package: libgmp10-stage
	# libgmp10.mk Package Structure
	rm -rf $(BUILD_DIST)/libgmp10
	mkdir -p $(BUILD_DIST)/libgmp10
	
	# libgmp10.mk Prep libgmp10
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libgmp10/usr $(BUILD_DIST)/libgmp10
	
	# libgmp10.mk Sign
	$(call SIGN,libgmp10,general.xml)
	
	# libgmp10.mk Make .debs
	$(call PACK,libgmp10,DEB_GMP_V)
	
	# libgmp10.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgmp10

.PHONY: libgmp10 libgmp10-package
