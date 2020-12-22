ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libvpx
LIBVPX_VERSION := 1.9.0
DEB_LIBVPX_V   ?= $(LIBVPX_VERSION)

libvpx-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libvpx-$(LIBVPX_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libvpx-$(LIBVPX_VERSION).tar.gz \
			https://github.com/webmproject/libvpx/archive/v$(LIBVPX_VERSION).tar.gz
	$(call EXTRACT_TAR,libvpx-$(LIBVPX_VERSION).tar.gz,libvpx-$(LIBVPX_VERSION),libvpx)

ifneq ($(wildcard $(BUILD_WORK)/libvpx/.build_complete),)
libvpx:
	@echo "Using previously built libvpx."
else
libvpx: libvpx-setup
	cd $(BUILD_WORK)/libvpx && ./configure \
		--target=arm64-darwin-gcc \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-shared \
		--disable-unit-tests \
		--enable-pic \
		--enable-postproc \
		--enable-multi-res-encoding \
		--enable-temporal-denoising \
		--enable-vp9-temporal-denoising \
		--enable-vp9-postproc \
		--enable-vp9-highbitdepth
	+$(MAKE) -C $(BUILD_WORK)/libvpx
	+$(MAKE) -C $(BUILD_WORK)/libvpx install \
		DESTDIR=$(BUILD_STAGE)/libvpx
	+$(MAKE) -C $(BUILD_WORK)/libvpx install \
		DESTDIR=$(BUILD_BASE)
	
	for bin in $(BUILD_STAGE)/libvpx/usr/bin/*; do \
		$(I_N_T) -change libvpx.6.dylib /usr/lib/libvpx.6.dylib $$bin; \
	done
	$(I_N_T) -id /usr/lib/libvpx.6.dylib $(BUILD_STAGE)/libvpx/usr/lib/libvpx.6.dylib
	$(I_N_T) -id /usr/lib/libvpx.6.dylib $(BUILD_BASE)/usr/lib/libvpx.6.dylib
	touch $(BUILD_WORK)/libvpx/.build_complete
endif

libvpx-package: libvpx-stage
	# libvpx.mk Package Structure
	rm -rf $(BUILD_DIST)/libvpx{6,-dev} $(BUILD_DIST)/vpx-tools
	mkdir -p $(BUILD_DIST)/libvpx{6,-dev}/usr/lib \
		$(BUILD_DIST)/vpx-tools/usr
	
	# libvpx.mk Prep libvpx6
	cp -a $(BUILD_STAGE)/libvpx/usr/lib/libvpx.6.dylib $(BUILD_DIST)/libvpx6/usr/lib
	
	# libvpx.mk Prep libvpx-dev
	cp -a $(BUILD_STAGE)/libvpx/usr/lib/!(libvpx.6.dylib) $(BUILD_DIST)/libvpx-dev/usr/lib
	cp -a $(BUILD_STAGE)/libvpx/usr/include $(BUILD_DIST)/libvpx-dev/usr
	
	# libvpx.mk Prep vpx-tools
	cp -a $(BUILD_STAGE)/libvpx/usr/bin $(BUILD_DIST)/vpx-tools/usr
	
	# libvpx.mk Sign
	$(call SIGN,libvpx6,general.xml)
	$(call SIGN,vpx-tools,general.xml)
	
	# libvpx.mk Make .debs
	$(call PACK,libvpx6,DEB_LIBVPX_V)
	$(call PACK,libvpx-dev,DEB_LIBVPX_V)
	$(call PACK,vpx-tools,DEB_LIBVPX_V)

	# libvpx.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvpx{6,-dev} $(BUILD_DIST)/vpx-tools

.PHONY: libvpx libvpx-package
