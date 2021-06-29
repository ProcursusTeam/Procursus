ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libebml
LIBEBML_VERSION := 1.4.2
DEB_LIBEBML_V   ?= $(LIBEBML_VERSION)

libebml-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dl.matroska.org/downloads/libebml/libebml-$(LIBEBML_VERSION).tar.xz
	$(call EXTRACT_TAR,libebml-$(LIBEBML_VERSION).tar.xz,libebml-$(LIBEBML_VERSION),libebml)

ifneq ($(wildcard $(BUILD_WORK)/libebml/.build_complete),)
libebml:
	@echo "Using previously built libebml."
else
libebml: libebml-setup
	cd $(BUILD_WORK)/libebml && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=ON \
		.
	+$(MAKE) -C $(BUILD_WORK)/libebml
	+$(MAKE) -C $(BUILD_WORK)/libebml install \
		DESTDIR="$(BUILD_STAGE)/libebml"
	+$(MAKE) -C $(BUILD_WORK)/libebml install \
		DESTDIR="$(BUILD_BASE)"

	touch $(BUILD_WORK)/libebml/.build_complete
endif

libebml-package: libebml-stage
	# libebml.mk Package Structure
	rm -rf $(BUILD_DIST)/libebml{5,-dev}
	mkdir -p $(BUILD_DIST)/libebml{5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libebml.mk Prep libebml5
	cp -a $(BUILD_STAGE)/libebml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libebml.5{,.0.0}.dylib $(BUILD_DIST)/libebml5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libebml.mk Prep libebml-dev (cmake files included for libmatroska)
	cp -a $(BUILD_STAGE)/libebml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libebml-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libebml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libebml.dylib $(BUILD_DIST)/libebml-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libebml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libebml-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libebml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/cmake $(BUILD_DIST)/libebml-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libebml.mk Sign
	$(call SIGN,libebml5,general.xml)

	# libebml.mk Make .debs
	$(call PACK,libebml5,DEB_LIBEBML_V)
	$(call PACK,libebml-dev,DEB_LIBEBML_V)

	# libebml.mk Build cleanup
	rm -rf $(BUILD_DIST)/libebml{5,-dev}

.PHONY: libebml libebml-package
