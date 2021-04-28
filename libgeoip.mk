ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libgeoip
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
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libgeoip
	+$(MAKE) -C $(BUILD_WORK)/libgeoip install \
		DESTDIR="$(BUILD_STAGE)/libgeoip"
	+$(MAKE) -C $(BUILD_WORK)/libgeoip install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgeoip/.build_complete
endif

libgeoip-package: libgeoip-stage
	# libgeoip Package Structure
	rm -rf $(BUILD_DIST)/libgeoip{1,-dev}
	mkdir -p \
		$(BUILD_DIST)/libgeoip1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgeoip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} \
		$(BUILD_DIST)/geoip-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libgeoip1 Prep libgeoip
	cp -a $(BUILD_STAGE)/libgeoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGeoIP{.1.dylib,.dylib} $(BUILD_DIST)/libgeoip1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgeoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libGeoIP.a $(BUILD_STAGE)/libgeoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libgeoip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgeoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/* $(BUILD_DIST)/libgeoip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libgeoip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/geoip-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libgeoip Sign
	$(call SIGN,libgeoip1,general.xml)
	$(call SIGN,libgeoip-dev,general.xml)
	$(call SIGN,geoip-bin,general.xml)

	# libgeoip Make .debs
	$(call PACK,libgeoip1,DEB_LIBGEOIP_V)
	$(call PACK,libgeoip-dev,DEB_LIBGEOIP_V)
	$(call PACK,geoip-bin,DEB_LIBGEOIP_V)


	# libgeoip Build cleanup
	rm -rf $(BUILD_DIST)/libgeoip{1,-dev} $(BUILD_DIST)/geoip-bin

.PHONY: libgeoip libgeoip-package