ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += nettle
NETTLE_VERSION := 3.6
DEB_NETTLE_V   ?= $(NETTLE_VERSION)

nettle-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/nettle/nettle-$(NETTLE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,nettle-$(NETTLE_VERSION).tar.gz)
	$(call EXTRACT_TAR,nettle-$(NETTLE_VERSION).tar.gz,nettle-$(NETTLE_VERSION),nettle)
	$(call DO_PATCH,nettle,nettle,-p1)

ifneq ($(wildcard $(BUILD_WORK)/nettle/.build_complete),)
nettle:
	@echo "Using previously built nettle."
else
nettle: nettle-setup libgmp10
	cd $(BUILD_WORK)/nettle && autoreconf -iv
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
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle8 \
		$(BUILD_DIST)/libhogweed6
	mkdir -p $(BUILD_DIST)/nettle-bin/usr \
		$(BUILD_DIST)/nettle-dev/usr/lib \
		$(BUILD_DIST)/libnettle8/usr/lib \
		$(BUILD_DIST)/libhogweed6/usr/lib
	
	# nettle.mk Prep nettle-bin
	cp -a $(BUILD_STAGE)/nettle/usr/bin $(BUILD_DIST)/nettle-bin/usr
	
	# nettle.mk Prep libnettle8
	cp -a $(BUILD_STAGE)/nettle/usr/lib/libnettle.8{,.0}.dylib $(BUILD_DIST)/libnettle8/usr/lib
	
	# nettle.mk Prep libhogweed6
	cp -a $(BUILD_STAGE)/nettle/usr/lib/libhogweed.6{,.0}.dylib $(BUILD_DIST)/libhogweed6/usr/lib
	
	# nettle.mk Prep nettle-dev
	cp -a $(BUILD_STAGE)/nettle/usr/lib/{pkgconfig,lib{nettle,hogweed}.{dylib,a}} $(BUILD_DIST)/nettle-dev/usr/lib
	cp -a $(BUILD_STAGE)/nettle/usr/include $(BUILD_DIST)/nettle-dev/usr
	
	# nettle.mk Sign
	$(call SIGN,nettle-bin,general.xml)
	$(call SIGN,libnettle8,general.xml)
	$(call SIGN,libhogweed6,general.xml)
	
	# nettle.mk Make .debs
	$(call PACK,nettle-bin,DEB_NETTLE_V)
	$(call PACK,nettle-dev,DEB_NETTLE_V)
	$(call PACK,libnettle8,DEB_NETTLE_V)
	$(call PACK,libhogweed6,DEB_NETTLE_V)
	
	# nettle.mk Build cleanup
	rm -rf $(BUILD_DIST)/nettle-bin \
		$(BUILD_DIST)/nettle-dev \
		$(BUILD_DIST)/libnettle8 \
		$(BUILD_DIST)/libhogweed6

.PHONY: nettle nettle-package
