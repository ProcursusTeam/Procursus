ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

IDN2_VERSION := 2.3.0
DEB_IDN2_V   ?= $(IDN2_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libidn2/.build_complete),)
libidn2:
	@echo "Using previously built libidn2."
else
libidn2: setup gettext
	cd $(BUILD_WORK)/libidn2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libidn2
	+$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_STAGE)/libidn2
	+$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libidn2/.build_complete
endif

libidn2-package: libidn2-stage
	# libidn2.mk Package Structure
	rm -rf $(BUILD_DIST)/libidn2
	mkdir -p $(BUILD_DIST)/libidn2
	
	# libidn2.mk Prep libidn2
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libidn2/usr $(BUILD_DIST)/libidn2
	
	# libidn2.mk Sign
	$(call SIGN,libidn2,general.xml)
	
	# libidn2.mk Make .debs
	$(call PACK,libidn2,DEB_IDN2_V)
	
	# libidn2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libidn2

.PHONY: libidn2 libidn2-package
