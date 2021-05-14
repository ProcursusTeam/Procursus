ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libbluray
LIBBLURAY_VERSION := 1.3.0
DEB_LIBBLURAY_V   ?= $(LIBBLURAY_VERSION)

libbluray-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libbluray/$(LIBBLURAY_VERSION)/libbluray-$(LIBBLURAY_VERSION).tar.bz2
	$(call EXTRACT_TAR,libbluray-$(LIBBLURAY_VERSION).tar.bz2,libbluray-$(LIBBLURAY_VERSION),libbluray)
	$(call DO_PATCH,libbluray,libbluray,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libbluray/.build_complete),)
libbluray:
	@echo "Using previously built libbluray."
else
libbluray: fontconfig expat libbluray-setup
	cd $(BUILD_WORK)/libbluray && ./bootstrap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libbluray
	+$(MAKE) -C $(BUILD_WORK)/libbluray install \
		DESTDIR=$(BUILD_STAGE)/libbluray
	+$(MAKE) -C $(BUILD_WORK)/libbluray install \
		DESTDIR=$(BUILD_BASE)

	touch $(BUILD_WORK)/libbluray/.build_complete
endif

libbluray-package: libbluray-stage
	# libbluray.mk Package Structure
	rm -rf $(BUILD_DIST)/libbluray{2,-dev,-bin,-bdj}
	mkdir -p $(BUILD_DIST)/libbluray{2,-dev,-bin,-bdj}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libbluray{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libbluray-bdj/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libbluray-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libbluray.mk Prep libbluray2
	cp -a $(BUILD_STAGE)/libbluray/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libbluray.2.dylib $(BUILD_DIST)/libbluray2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libbluray.mk Prep libbluray-dev
	cp -a $(BUILD_STAGE)/libbluray/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libbluray-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libbluray/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libbluray.{dylib,la,a},pkgconfig} $(BUILD_DIST)/libbluray-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libbluray.mk Prep libbluray-bin
	cp -a $(BUILD_STAGE)/libbluray/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libbluray-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libbluray.mk Prep libbluray-bdj
	cp -a $(BUILD_STAGE)/libbluray/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/java $(BUILD_DIST)/libbluray-bdj/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libbluray.mk Sign
	$(call SIGN,libbluray2,general.xml)
	$(call SIGN,libbluray-bin,general.xml)
	
	# libbluray.mk Make .debs
	$(call PACK,libbluray2,DEB_LIBBLURAY_V)
	$(call PACK,libbluray-dev,DEB_LIBBLURAY_V)
	$(call PACK,libbluray-bin,DEB_LIBBLURAY_V)
	$(call PACK,libbluray-bdj,DEB_LIBBLURAY_V)
	
	# libbluray.mk Build cleanup
	rm -rf $(BUILD_DIST)/libbluray{2,-dev,-bin,-bdj}

.PHONY: libbluray libbluray-package
