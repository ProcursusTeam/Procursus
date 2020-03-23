ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

P11_VERSION := 0.23.20
DEB_P11_V   ?= $(P11_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/p11-kit/.build_complete),)
p11-kit:
	@echo "Using previously built p11-kit."
else
p11-kit: setup gettext libtasn1
	cd $(BUILD_WORK)/p11-kit && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-trust-paths \
		--without-libffi
	$(MAKE) -C $(BUILD_WORK)/p11-kit
	$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_STAGE)/p11-kit
	$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/p11-kit/.build_complete
endif

.PHONY: p11-kit
