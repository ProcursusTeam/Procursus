ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += dav1d
DAV1D_VERSION := 0.7.1
DEB_DAV1D_V   ?= $(DAV1D_VERSION)

dav1d-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.videolan.org/pub/videolan/dav1d/$(DAV1D_VERSION)/dav1d-$(DAV1D_VERSION).tar.xz
	$(call EXTRACT_TAR,dav1d-$(DAV1D_VERSION).tar.xz,dav1d-$(DAV1D_VERSION),dav1d)
	mkdir -p $(BUILD_WORK)/dav1d/build

	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(ARCHES)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='/usr'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/dav1d/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/dav1d/.build_complete),)
dav1d:
	@echo "Using previously built dav1d."
else
dav1d: dav1d-setup
	cd $(BUILD_WORK)/dav1d/build && meson \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/dav1d/build
	+DESTDIR=$(BUILD_STAGE)/dav1d ninja -C $(BUILD_WORK)/dav1d/build install
	+DESTDIR=$(BUILD_BASE) ninja -C $(BUILD_WORK)/dav1d/build install
	touch $(BUILD_WORK)/dav1d/.build_complete
endif

dav1d-package: dav1d-stage
	# dav1d.mk Package Structure
	rm -rf $(BUILD_DIST)/dav1d \
		$(BUILD_DIST)/libdav1d{-dev,4}
	mkdir -p $(BUILD_DIST)/dav1d/usr/ \
		$(BUILD_DIST)/libdav1d{4,-dev}/usr/lib
	
	# dav1d.mk Prep dav1d
	cp -a $(BUILD_STAGE)/dav1d/usr/bin $(BUILD_DIST)/dav1d/usr
	
	# dav1d.mk Prep libdav1d4
	cp -a $(BUILD_STAGE)/dav1d/usr/lib/libdav1d.4.dylib $(BUILD_DIST)/libdav1d4/usr/lib
	
	# dav1d.mk Prep libdav1d-dev
	cp -a $(BUILD_STAGE)/dav1d/usr/lib/{libdav1d.dylib,pkgconfig} $(BUILD_DIST)/libdav1d-dev/usr/lib
	cp -a $(BUILD_STAGE)/dav1d/usr/include $(BUILD_DIST)/libdav1d-dev/usr
	
	# dav1d.mk Sign
	$(call SIGN,dav1d,general.xml)
	$(call SIGN,libdav1d4,general.xml)
	
	# dav1d.mk Make .debs
	$(call PACK,dav1d,DEB_DAV1D_V)
	$(call PACK,libdav1d4,DEB_DAV1D_V)
	$(call PACK,libdav1d-dev,DEB_DAV1D_V)
	
	# dav1d.mk Build cleanup
	rm -rf $(BUILD_DIST)/dav1d \
		$(BUILD_DIST)/libdav1d{-dev,4}

.PHONY: dav1d dav1d-package
