ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libde265
LIBDE265_VERSION := 1.0.8
DEB_LIBDE265_V   ?= $(LIBDE265_VERSION)

libde265-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/strukturag/libde265/releases/download/v$(LIBDE265_VERSION)/libde265-$(LIBDE265_VERSION).tar.gz
	$(call EXTRACT_TAR,libde265-$(LIBDE265_VERSION).tar.gz,libde265-$(LIBDE265_VERSION),libde265)

ifneq ($(wildcard $(BUILD_WORK)/libde265/.build_complete),)
libde265:
	@echo "Using previously built libde265."
else
libde265: libde265-setup
	cd $(BUILD_WORK)/libde265 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-sherlock265
	+$(MAKE) -C $(BUILD_WORK)/libde265
	+$(MAKE) -C $(BUILD_WORK)/libde265 install \
		DESTDIR=$(BUILD_STAGE)/libde265
	+$(MAKE) -C $(BUILD_WORK)/libde265 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libde265/.build_complete
endif

libde265-package: libde265-stage
	# libde265.mk Package Structure
	rm -rf $(BUILD_DIST)/libde265-{0,dev,examples}
	mkdir -p $(BUILD_DIST)/libde265-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libde265-examples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libde265.mk Prep libde265-0
	cp -a $(BUILD_STAGE)/libde265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libde265.0.dylib $(BUILD_DIST)/libde265-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libde265.mk Prep libde265-dev
	cp -a $(BUILD_STAGE)/libde265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libde265.{dylib,a},pkgconfig} $(BUILD_DIST)/libde265-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libde265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libde265-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libde265.mk Prep libde265-examples
	cp -a $(BUILD_STAGE)/libde265/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dec265 $(BUILD_DIST)/libde265-examples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/libde265-dec265

	# libde265.mk Sign
	$(call SIGN,libde265-0,general.xml)
	$(call SIGN,libde265-examples,general.xml)

	# libde265.mk Make .debs
	$(call PACK,libde265-0,DEB_LIBDE265_V)
	$(call PACK,libde265-dev,DEB_LIBDE265_V)
	$(call PACK,libde265-examples,DEB_LIBDE265_V)

	# libde265.mk Build cleanup
	rm -rf $(BUILD_DIST)/libde265-{0,dev,examples}

.PHONY: libde265 libde265-package
