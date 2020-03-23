ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBTASN1_VERSION := 4.16.0
DEB_LIBTASN1_V   ?= $(LIBTASN1_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libtasn1/.build_complete),)
libtasn1:
	@echo "Using previously built libtasn1."
else
libtasn1: setup
	cd $(BUILD_WORK)/libtasn1 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/libtasn1
	$(MAKE) -C $(BUILD_WORK)/libtasn1 install \
		DESTDIR=$(BUILD_STAGE)/libtasn1
	$(MAKE) -C $(BUILD_WORK)/libtasn1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libtasn1/.build_complete
endif

.PHONY: libtasn1
