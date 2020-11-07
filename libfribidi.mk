ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libfribidi
LIBFRIBIDI_VERSION := 1.0.10
DEB_LIBFRIBIDI_V   ?= $(LIBFRIBIDI_VERSION)

libfribidi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/fribidi/fribidi/releases/download/v$(LIBFRIBIDI_VERSION)/fribidi-$(LIBFRIBIDI_VERSION).tar.xz
	$(call EXTRACT_TAR,fribidi-$(LIBFRIBIDI_VERSION).tar.xz,fribidi-$(LIBFRIBIDI_VERSION),libfribidi)

ifneq ($(wildcard $(BUILD_WORK)/libfribidi/.build_complete),)
libfribidi:
	@echo "Using previously built libfribidi."
else
libfribidi: libfribidi-setup
	cd $(BUILD_WORK)/libfribidi && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-silent-rules \
		--disable-debug
	+$(MAKE) -C $(BUILD_WORK)/libfribidi
	+$(MAKE) -C $(BUILD_WORK)/libfribidi install \
		DESTDIR=$(BUILD_STAGE)/libfribidi
	+$(MAKE) -C $(BUILD_WORK)/libfribidi install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libfribidi/.build_complete
endif

libfribidi-package: libfribidi-stage
	# libfribidi.mk Package Structure
	rm -rf $(BUILD_DIST)/libfribidi{0,-dev,-bin}
	mkdir -p $(BUILD_DIST)/libfribidi{0,-dev}/usr/lib \
		$(BUILD_DIST)/libfribidi-bin/usr

	# libfribidi.mk Prep libfribidi0
	cp -a $(BUILD_STAGE)/libfribidi/usr/lib/libfribidi.0.dylib $(BUILD_DIST)/libfribidi0/usr/lib

	# libfribidi.mk Prep libfribidi-dev
	cp -a $(BUILD_STAGE)/libfribidi/usr/lib/libfribidi.dylib $(BUILD_DIST)/libfribidi-dev/usr/lib
	cp -a $(BUILD_STAGE)/libfribidi/usr/include $(BUILD_DIST)/libfribidi-dev/usr
	cp -a $(BUILD_STAGE)/libfribidi/usr/share $(BUILD_DIST)/libfribidi-dev/usr

	# libfribidi.mk Prep libfribidi-bin
	cp -a $(BUILD_STAGE)/libfribidi/usr/bin $(BUILD_DIST)/libfribidi-bin/usr

	# libfribidi.mk Sign
	$(call SIGN,libfribidi0,general.xml)
	$(call SIGN,libfribidi-bin,general.xml)
	
	# libfribidi.mk Make .debs
	$(call PACK,libfribidi0,DEB_LIBFRIBIDI_V)
	$(call PACK,libfribidi-dev,DEB_LIBFRIBIDI_V)
	$(call PACK,libfribidi-bin,DEB_LIBFRIBIDI_V)
	
	# libfribidi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfribidi{0,-dev,-bin}

.PHONY: libfribidi libfribidi-package
