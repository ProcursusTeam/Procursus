ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += jansson
JANSSON_VERSION := 2.13.1
DEB_JANSSON_V   ?= $(JANSSON_VERSION)

jansson-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://digip.org/jansson/releases/jansson-$(JANSSON_VERSION).tar.gz
	$(call EXTRACT_TAR,jansson-$(JANSSON_VERSION).tar.gz,jansson-$(JANSSON_VERSION),jansson)

	
ifneq ($(wildcard $(BUILD_WORK)/jansson/.build_complete),)
jansson:
	@echo "Using previously built jansson."
else
jansson: jansson-setup
	cd $(BUILD_WORK)/jansson && ./configure \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/jansson
	+$(MAKE) -C $(BUILD_WORK)/jansson install \
		DESTDIR="$(BUILD_STAGE)/jansson"
	+$(MAKE) -C $(BUILD_WORK)/jansson install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/jansson/.build_complete
endif


jansson-package: jansson-stage
	# jansson.mk Package Structure
	mkdir -p $(BUILD_DIST)/libjansson-dev/usr/{include,lib} \
		$(BUILD_DIST)/libjansson4/usr/{lib,} \
	
	# jansson.mk Prep libjanssson-dev
	cp -a $(BUILD_STAGE)/jansson/usr/local/include/*.h $(BUILD_DIST)/libjansson-dev/usr/include
	cp -a $(BUILD_STAGE)/jansson/usr/local/lib/libjansson.a $(BUILD_DIST)/libjansson-dev/usr/lib
	cp -a $(BUILD_STAGE)/jansson/usr/local/lib/libjansson.la $(BUILD_DIST)/libjansson-dev/usr/lib
	cp -a $(BUILD_STAGE)/jansson/usr/local/lib/pkgconfig $(BUILD_DIST)/libjansson-dev/usr/lib
	
	# jansson.mk Prep libjansson4
	cp -a $(BUILD_STAGE)/jansson/usr/local/lib/libjansson*.d* $(BUILD_DIST)/libjansson4/usr/lib
	
	# jansson.mk Sign
	$(call SIGN,jansson,general.xml)
	
	# jansson.mk Make .debs
	$(call PACK,libjansson-dev,DEB_JANSSON_V)
	$(call PACK,libjansson4,DEB_JANSSON_V)
	
	# jansson.mk Build cleanup
	rm -rf $(BUILD_DIST)/jansson 
	rm -rf $(BUILD_DIST)libjansson-dev
	rm -rf $(BUILD_DIST)/libjansson4
	
.PHONY: jansson jansson-package
