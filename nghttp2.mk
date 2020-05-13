ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += nghttp2
DOWNLOAD        += https://github.com/nghttp2/nghttp2/releases/download/v$(NGHTTP2_VERSION)/nghttp2-$(NGHTTP2_VERSION).tar.xz
NGHTTP2_VERSION := 1.40.0
DEB_NGHTTP2_V   ?= $(NGHTTP2_VERSION)

nghttp2-setup: setup
	$(call EXTRACT_TAR,nghttp2-$(NGHTTP2_VERSION).tar.xz,nghttp2-$(NGHTTP2_VERSION),nghttp2)

ifneq ($(wildcard $(BUILD_WORK)/nghttp2/.build_complete),)
nghttp2:
	@echo "Using previously built nghttp2."
else
nghttp2: nghttp2-setup
	cd $(BUILD_WORK)/nghttp2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-lib-only
	+$(MAKE) -C $(BUILD_WORK)/nghttp2
	+$(MAKE) -C $(BUILD_WORK)/nghttp2 install \
		DESTDIR="$(BUILD_STAGE)/nghttp2"
	+$(MAKE) -C $(BUILD_WORK)/nghttp2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/nghttp2/.build_complete
endif

nghttp2-package: nghttp2-stage
	# nghttp2.mk Package Structure
	rm -rf $(BUILD_DIST)/libnghttp2-{14,dev}
	mkdir -p $(BUILD_DIST)/libnghttp2-{14,dev}/usr/lib
	
	# nghttp2.mk Prep libnghttp2-14
	cp -a $(BUILD_STAGE)/nghttp2/usr/lib/*.dylib $(BUILD_DIST)/libnghttp2-14/usr/lib
	
	# nghttp2.mk Prep libnghttp2-dev
	cp -a $(BUILD_STAGE)/nghttp2/usr/lib/pkgconfig $(BUILD_DIST)/libnghttp2-dev/usr/lib
	cp -a $(BUILD_STAGE)/nghttp2/usr/include $(BUILD_DIST)/libnghttp2-dev/usr
	
	#nghttp2.mk Sign
	$(call SIGN,libnghttp2-14,general.xml)
	
	# nghttp2.mk Make .debs
	$(call PACK,libnghttp2-14,DEB_NGHTTP2_V)
	$(call PACK,libnghttp2-dev,DEB_NGHTTP2_V)
	
	# nghttp2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnghttp2-{14,dev}

.PHONY: nghttp2 nghttp2-package
