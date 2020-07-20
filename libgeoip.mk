
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libgeoip
LIBGEOIP_VERSION := 1.6.12
DEB_LIBGEOIP_V   ?= $(LIBGEOIP_VERSION)

libgeoip-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://github.com/maxmind/geoip-api-c/releases/download/v1.6.12/GeoIP-$(LIBGEOIP_VERSION).tar.gz
	$(call EXTRACT_TAR,GeoIP-$(LIBGEOIP_VERSION).tar.gz,GeoIP-$(LIBGEOIP_VERSION),libgeoip)
	$(SED) -i '/AC_FUNC_MALLOC/d' $(BUILD_WORK)/libgeoip/configure.ac
	$(SED) -i '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/libgeoip/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libgeoip/.build_complete),)
libgeoip:
	@echo "Using previously built libgeoip."
else
libgeoip: libgeoip-setup
	cd $(BUILD_WORK)/libgeoip && autoreconf -f -i && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libgeoip
	+$(MAKE) -C $(BUILD_WORK)/libgeoip install \
		DESTDIR="$(BUILD_STAGE)/libgeoip"
	+$(MAKE) -C $(BUILD_WORK)/libgeoip install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgeoip/.build_complete
endif

libgeoip-package: libgeoip-stage
  # libgeoip.mk Package Structure
	rm -rf $(BUILD_DIST)/libgeoip
	mkdir -p $(BUILD_DIST)/libgeoip

  # libgeoip.mk Prep libgeoip
	cp -a $(BUILD_STAGE)/libgeoip/usr $(BUILD_DIST)/libgeoip

  # libgeoip.mk Sign
	$(call SIGN,libgeoip,general.xml)

  # libgeoip.mk Make .debs
	$(call PACK,libgeoip,DEB_LIBGEOIP_V)

  # libgeoip.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgeoip

.PHONY: libgeoip libgeoip-package
