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
	$(MAKE) -C $(BUILD_WORK)/libidn2
	$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_STAGE)/libidn2
	$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libidn2/.build_complete
endif

.PHONY: libidn2
