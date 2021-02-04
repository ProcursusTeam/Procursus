ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += libpugixml
LIBPUGIXML_VERSION     := 1.11.4
DEB_LIBPUGIXML_V       ?= $(LIBPUGIXML_VERSION)

libpugixml-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/zeux/pugixml/releases/download/v$(LIBPUGIXML_VERSION)/pugixml-$(LIBPUGIXML_VERSION).tar.gz
	$(call EXTRACT_TAR,pugixml-$(LIBPUGIXML_VERSION).tar.gz,pugixml-$(LIBPUGIXML_VERSION),libpugixml)

ifneq ($(wildcard $(BUILD_WORK)/libpugixml/.build_complete),)
libpugixml:
	@echo "Using previously built libpugixml."
else
libpugixml: libpugixml-setup
	cd $(BUILD_WORK)/libpugixml && cmake . \
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
		-DBUILD_SHARED_AND_STATIC_LIBS=ON
	+$(MAKE) -C $(BUILD_WORK)/libpugixml
	+$(MAKE) -C $(BUILD_WORK)/libpugixml install \
		DESTDIR="$(BUILD_STAGE)/libpugixml"
	+$(MAKE) -C $(BUILD_WORK)/libpugixml install \
		DESTDIR="$(BUILD_BASE)"
	
	touch $(BUILD_WORK)/libpugixml/.build_complete
endif

libpugixml-package: libpugixml-stage
	# libpugixml.mk Package Structure
	rm -rf $(BUILD_DIST)/libpugixml{1,-dev}
	mkdir -p $(BUILD_DIST)/libpugixml{1,-dev}/usr/lib

	# libpugixml.mk Prep libpugixml1
	cp -a $(BUILD_STAGE)/libpugixml/usr/lib/libpugixml.1*.dylib $(BUILD_DIST)/libpugixml1/usr/lib

	# libpugixml.mk Prep libpugixml-dev
	cp -a $(BUILD_STAGE)/libpugixml/usr/include $(BUILD_DIST)/libpugixml-dev/usr
	cp -a $(BUILD_STAGE)/libpugixml/usr/lib/libpugixml.{dylib,a} $(BUILD_DIST)/libpugixml-dev/usr/lib
	cp -a $(BUILD_STAGE)/libpugixml/usr/lib/pkgconfig $(BUILD_DIST)/libpugixml-dev/usr/lib

	# libpugixml.mk Sign
	$(call SIGN,libpugixml1,general.xml)

	# libpugixml.mk Make .debs
	$(call PACK,libpugixml1,DEB_LIBPUGIXML_V)
	$(call PACK,libpugixml-dev,DEB_LIBPUGIXML_V)

	# libpugixml.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpugixml{1,-dev}

.PHONY: libpugixml libpugixml-package
