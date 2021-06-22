ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libvpx
LIBVPX_VERSION := 1.10.0
DEB_LIBVPX_V   ?= $(LIBVPX_VERSION)

ifneq (,$(findstring arm64,$(MEMO_TARGET)))
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LIBVPX_CONFIGURE_FLAGS := --target=arm64-darwin$(DARWIN_DEPLOYMENT_VERSION)-gcc
else
LIBVPX_CONFIGURE_FLAGS := --target=arm64-darwin-gcc
endif
else
LIBVPX_CONFIGURE_FLAGS := --target=x86_64-darwin$(DARWIN_DEPLOYMENT_VERSION)-gcc
endif

libvpx-setup: setup
	$(call GITHUB_ARCHIVE,webmproject,libvpx,$(LIBVPX_VERSION),v$(LIBVPX_VERSION))
	$(call EXTRACT_TAR,libvpx-$(LIBVPX_VERSION).tar.gz,libvpx-$(LIBVPX_VERSION),libvpx)

ifneq ($(wildcard $(BUILD_WORK)/libvpx/.build_complete),)
libvpx:
	@echo "Using previously built libvpx."
else
libvpx: libvpx-setup
	cd $(BUILD_WORK)/libvpx && ./configure \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-dependency-tracking \
		--enable-shared \
		--disable-unit-tests \
		--enable-pic \
		--enable-postproc \
		--enable-multi-res-encoding \
		--enable-temporal-denoising \
		--enable-vp9-temporal-denoising \
		--enable-vp9-postproc \
		--enable-vp9-highbitdepth \
		$(LIBVPX_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libvpx
	+$(MAKE) -C $(BUILD_WORK)/libvpx install \
		DESTDIR=$(BUILD_STAGE)/libvpx
	+$(MAKE) -C $(BUILD_WORK)/libvpx install \
		DESTDIR=$(BUILD_BASE)

	for bin in $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		$(I_N_T) -change libvpx.6.dylib /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib $$bin; \
	done
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib
	touch $(BUILD_WORK)/libvpx/.build_complete
endif

libvpx-package: libvpx-stage
	# libvpx.mk Package Structure
	rm -rf $(BUILD_DIST)/libvpx{6,-dev} $(BUILD_DIST)/vpx-tools
	mkdir -p $(BUILD_DIST)/libvpx{6,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/vpx-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libvpx.mk Prep libvpx6
	cp -a $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvpx.6.dylib $(BUILD_DIST)/libvpx6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libvpx.mk Prep libvpx-dev
	cp -a $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libvpx.6.dylib) $(BUILD_DIST)/libvpx-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libvpx-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libvpx.mk Prep vpx-tools
	cp -a $(BUILD_STAGE)/libvpx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/vpx-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

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
