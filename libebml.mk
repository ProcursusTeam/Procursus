ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libebml
LIBEBML_VERSION     := 1.4.1
DEB_LIBEBML_V       ?= $(LIBEBML_VERSION)

libebml-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dl.matroska.org/downloads/libebml/libebml-$(LIBEBML_VERSION).tar.xz
	$(call EXTRACT_TAR,libebml-$(LIBEBML_VERSION).tar.xz,libebml-$(LIBEBML_VERSION),libebml)

ifneq ($(wildcard $(BUILD_WORK)/libebml/.build_complete),)
libebml:
	@echo "Using previously built libebml."
else
libebml: libebml-setup
	cd $(BUILD_WORK)/libebml && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_CXX_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
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
	mkdir -p $(BUILD_DIST)/libebml{5,-dev}/usr/lib

	# libebml.mk Prep libebml5
	cp -a $(BUILD_STAGE)/libebml/usr/lib/libebml.5{,.0.0}.dylib $(BUILD_DIST)/libebml5/usr/lib

	# libebml.mk Prep libebml-dev (cmake files included for libmatroska)
	cp -a $(BUILD_STAGE)/libebml/usr/include $(BUILD_DIST)/libebml-dev/usr
	cp -a $(BUILD_STAGE)/libebml/usr/lib/libebml.dylib $(BUILD_DIST)/libebml-dev/usr/lib
	cp -a $(BUILD_STAGE)/libebml/usr/lib/pkgconfig $(BUILD_DIST)/libebml-dev/usr/lib
	cp -a $(BUILD_STAGE)/libebml/usr/lib/cmake $(BUILD_DIST)/libebml-dev/usr/lib

	# libebml.mk Sign
	$(call SIGN,libebml5,general.xml)

	# libebml.mk Make .debs
	$(call PACK,libebml5,DEB_LIBEBML_V)
	$(call PACK,libebml-dev,DEB_LIBEBML_V)

	# libebml.mk Build cleanup
	rm -rf $(BUILD_DIST)/libebml{5,-dev}

.PHONY: libebml libebml-package
