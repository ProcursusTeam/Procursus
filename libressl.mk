ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBRESSL_VERSION := 3.0.2
DEB_LIBRESSL_V   ?= $(LIBRESSL_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libressl/.build_complete),)
libressl:
	@echo "Using previously built libressl."
else
libressl: setup
	cd $(BUILD_WORK)/libressl && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-openssldir=/etc/ssl \
		--sysconfdir=/etc
	$(MAKE) -C $(BUILD_WORK)/libressl
	$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_STAGE)/libressl
	$(MAKE) -C $(BUILD_WORK)/libressl install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libressl/.build_complete
endif

.PHONY: libressl
