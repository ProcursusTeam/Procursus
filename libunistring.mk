ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

UNISTRING_VERSION := 0.9.10
DEB_UNISTRING_V   ?= $(UNISTRING_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libunistring/.build_complete),)
libunistring:
	@echo "Using previously built libunistring."
else
libunistring: setup
	cd $(BUILD_WORK)/libunistring && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/libunistring
	$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_STAGE)/libunistring
	$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libunistring/.build_complete
endif

.PHONY: libunistring
