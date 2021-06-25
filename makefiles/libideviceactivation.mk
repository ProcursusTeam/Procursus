ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += libideviceactivation
LIBIDEVICEACTIVATION_VERSION := 1.1.1
DEB_LIBIDEVICEACTIVATION_V   ?= $(LIBIDEVICEACTIVATION_VERSION)-1

libideviceactivation-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libimobiledevice/libideviceactivation/releases/download/$(LIBIDEVICEACTIVATION_VERSION)/libideviceactivation-$(LIBIDEVICEACTIVATION_VERSION).tar.bz2
	$(call EXTRACT_TAR,libideviceactivation-$(LIBIDEVICEACTIVATION_VERSION).tar.bz2,libideviceactivation-$(LIBIDEVICEACTIVATION_VERSION),libideviceactivation)

ifneq ($(wildcard $(BUILD_WORK)/libideviceactivation/.build_complete),)
libideviceactivation:
	@echo "Using previously built libideviceactivation."
else
libideviceactivation: libideviceactivation-setup libplist libimobiledevice curl
	cd $(BUILD_WORK)/libideviceactivation && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		libxml2_CFLAGS=-I$(TARGET_SYSROOT)/usr/include/libxml2 \
		libxml2_LIBS=-lxml2
	+$(MAKE) -C $(BUILD_WORK)/libideviceactivation
	+$(MAKE) -C $(BUILD_WORK)/libideviceactivation install \
		DESTDIR=$(BUILD_STAGE)/libideviceactivation
	+$(MAKE) -C $(BUILD_WORK)/libideviceactivation install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libideviceactivation/.build_complete
endif

libideviceactivation-package: libideviceactivation-stage
	# libideviceactivation.mk Package Structure
	rm -rf $(BUILD_DIST)/libideviceactivation{2,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libideviceactivation2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libideviceactivation-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,bin} \
		$(BUILD_DIST)/libideviceactivation-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libideviceactivation.mk Prep libideviceactivation
	cp -a $(BUILD_STAGE)/libideviceactivation/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libideviceactivation-1.0.2.dylib $(BUILD_DIST)/libideviceactivation2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libideviceactivation/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/libideviceactivation-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libideviceactivation/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libideviceactivation-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libideviceactivation/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libideviceactivation-1.0.{a,dylib}} $(BUILD_DIST)/libideviceactivation-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libideviceactivation.mk Sign
	$(call SIGN,libideviceactivation2,general.xml)
	$(call SIGN,libideviceactivation-utils,general.xml)

	# libideviceactivation.mk Make .debs
	$(call PACK,libideviceactivation2,DEB_LIBIDEVICEACTIVATION_V)
	$(call PACK,libideviceactivation-dev,DEB_LIBIDEVICEACTIVATION_V)
	$(call PACK,libideviceactivation-utils,DEB_LIBIDEVICEACTIVATION_V)

	# libideviceactivation.mk Build cleanup
	rm -rf $(BUILD_DIST)/libideviceactivation{2,-dev,-utils}

.PHONY: libideviceactivation libideviceactivation-package
