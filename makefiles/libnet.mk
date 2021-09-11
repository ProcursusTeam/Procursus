ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libnet
LIBNET_VERSION := 1.2
DEB_LIBNET_V   ?= $(LIBNET_VERSION)

libnet-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libnet/libnet/releases/download/v$(LIBNET_VERSION)/libnet-$(LIBNET_VERSION).tar.gz
	$(call EXTRACT_TAR,libnet-$(LIBNET_VERSION).tar.gz,libnet-$(LIBNET_VERSION),libnet)

ifneq ($(wildcard $(BUILD_WORK)/libnet/.build_complete),)
libnet:
	@echo "Using previously built libnet."
else
libnet: libnet-setup
	cd $(BUILD_WORK)/libnet && autoreconf -fi
	cd $(BUILD_WORK)/libnet && ./autogen.sh
	cd $(BUILD_WORK)/libnet && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)\
		--with-link-layer=bpf
	+$(MAKE) -C $(BUILD_WORK)/libnet
	+$(MAKE) -C $(BUILD_WORK)/libnet install \
		DESTDIR="$(BUILD_STAGE)/libnet"
	$(call AFTER_BUILD,copy)
endif

libnet-package: libnet-stage
	# libnet.mk Package Structure
	rm -rf $(BUILD_DIST)/libnet

	# libnet.mk Prep libnet
	cp -a $(BUILD_STAGE)/libnet $(BUILD_DIST)

	# libnet.mk Sign
	$(call SIGN,libnet,general.xml)

	# libnet.mk Make .debs
	$(call PACK,libnet,DEB_LIBNET_V)

	# libnet.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnet

.PHONY: libnet libnet-package
