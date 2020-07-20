ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libwebp
LIBWEBP_VERSION := 1.1.0
DEB_LIBWEBP_V   ?= $(LIBWEBP_VERSION)

libwebp-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz" ] && wget -q -nc -L -O$(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz \
		https://chromium.googlesource.com/webm/libwebp/+archive/refs/heads/$(LIBWEBP_VERSION).tar.gz
	# Fuck this lib.
	mkdir -p $(BUILD_WORK)/libwebp
	$(TAR) xf $(BUILD_SOURCE)/libwebp-$(LIBWEBP_VERSION).tar.gz -C $(BUILD_WORK)/libwebp


ifneq ($(wildcard $(BUILD_WORK)/libwebp/.build_complete),)
libwebp:
	@echo "Using previously built libwebp."
else
libwebp: libwebp-setup libjpeg libpng16 libgif libtiff
	cd $(BUILD_WORK)/libwebp && cmake . && ./configure -C \
		--enable-libwebpmux --enable-libwebpdemux --enable-libwebpdecoder --enable-libwebpextras \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libwebp
	+$(MAKE) -C $(BUILD_WORK)/libwebp install \
		DESTDIR="$(BUILD_STAGE)/libwebp"
	+$(MAKE) -C $(BUILD_WORK)/libwebp install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libwebp/.build_complete
endif

libwebp-package: libwebp-stage
  # libwebp.mk Package Structure
	rm -rf $(BUILD_DIST)/libwebp
	mkdir -p $(BUILD_DIST)/libwebp

  # libwebp.mk Prep libwebp
	cp -a $(BUILD_STAGE)/libwebp/usr $(BUILD_DIST)/libwebp

  # libwebp.mk Sign
	$(call SIGN,libwebp,general.xml)

  # libwebp.mk Make .debs
	$(call PACK,libwebp,DEB_LIBWEBP_V)

  # libwebp.mk Build cleanup
	rm -rf $(BUILD_DIST)/libwebp

.PHONY: libwebp libwebp-package
