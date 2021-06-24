ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += dav1d
DAV1D_VERSION := 0.9.0
DEB_DAV1D_V   ?= $(DAV1D_VERSION)

dav1d-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.videolan.org/pub/videolan/dav1d/$(DAV1D_VERSION)/dav1d-$(DAV1D_VERSION).tar.xz
	$(call EXTRACT_TAR,dav1d-$(DAV1D_VERSION).tar.xz,dav1d-$(DAV1D_VERSION),dav1d)
	mkdir -p $(BUILD_WORK)/dav1d/build

	echo -e "[host_machine]\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	system = 'darwin'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/dav1d/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/dav1d/.build_complete),)
dav1d:
	@echo "Using previously built dav1d."
else
dav1d: dav1d-setup
	cd $(BUILD_WORK)/dav1d/build && meson \
		--cross-file cross.txt \
		..
	$(SED) -i 's/HAVE_AS_FUNC 1/HAVE_AS_FUNC 0/' $(BUILD_WORK)/dav1d/build/config.h
	+ninja -C $(BUILD_WORK)/dav1d/build
	+DESTDIR=$(BUILD_STAGE)/dav1d ninja -C $(BUILD_WORK)/dav1d/build install
	+DESTDIR=$(BUILD_BASE) ninja -C $(BUILD_WORK)/dav1d/build install
	touch $(BUILD_WORK)/dav1d/.build_complete
endif

dav1d-package: dav1d-stage
	# dav1d.mk Package Structure
	rm -rf $(BUILD_DIST)/dav1d \
		$(BUILD_DIST)/libdav1d{-dev,5}
	mkdir -p $(BUILD_DIST)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ \
		$(BUILD_DIST)/libdav1d{5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dav1d.mk Prep dav1d
	cp -a $(BUILD_STAGE)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# dav1d.mk Prep libdav1d5
	cp -a $(BUILD_STAGE)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdav1d.5.dylib $(BUILD_DIST)/libdav1d5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dav1d.mk Prep libdav1d-dev
	cp -a $(BUILD_STAGE)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libdav1d.5.dylib) $(BUILD_DIST)/libdav1d-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/dav1d/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libdav1d-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# dav1d.mk Sign
	$(call SIGN,dav1d,general.xml)
	$(call SIGN,libdav1d5,general.xml)

	# dav1d.mk Make .debs
	$(call PACK,dav1d,DEB_DAV1D_V)
	$(call PACK,libdav1d5,DEB_DAV1D_V)
	$(call PACK,libdav1d-dev,DEB_DAV1D_V)

	# dav1d.mk Build cleanup
	rm -rf $(BUILD_DIST)/dav1d \
		$(BUILD_DIST)/libdav1d{-dev,5}

.PHONY: dav1d dav1d-package
