ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libtheora
LIBTHEORA_VERSION := 1.1.1
DEB_LIBTHEORA_V   ?= $(LIBTHEORA_VERSION)

libtheora-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.xiph.org/releases/theora/libtheora-$(LIBTHEORA_VERSION).tar.xz
	$(call EXTRACT_TAR,libtheora-$(LIBTHEORA_VERSION).tar.xz,libtheora-$(LIBTHEORA_VERSION),libtheora)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/libtheora

ifneq ($(wildcard $(BUILD_WORK)/libtheora/.build_complete),)
libtheora:
	@echo "Using previously built libtheora."
else
libtheora: libtheora-setup libogg
	cd $(BUILD_WORK)/libtheora && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--disable-oggtest \
		--disable-vorbistest \
		--disable-sdltest \
		--disable-examples \
		--disable-spec
	+$(MAKE) -C $(BUILD_WORK)/libtheora
	+$(MAKE) -C $(BUILD_WORK)/libtheora install \
		DESTDIR=$(BUILD_STAGE)/libtheora
	+$(MAKE) -C $(BUILD_WORK)/libtheora install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtheora/.build_complete
endif

libtheora-package: libtheora-stage
	# libtheora.mk Package Structure
	rm -rf $(BUILD_DIST)/libtheora{0,-dev}
	mkdir -p $(BUILD_DIST)/libtheora{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtheora.mk Prep libtheora0
	cp -a $(BUILD_STAGE)/libtheora/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtheora{.0,dec.1,enc.1}.dylib $(BUILD_DIST)/libtheora0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtheora.mk Prep libtheora-dev
	cp -a $(BUILD_STAGE)/libtheora/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtheora{,dec,enc}.{dylib,a} $(BUILD_DIST)/libtheora-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libtheora/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtheora-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libtheora.mk Sign
	$(call SIGN,libtheora0,general.xml)

	# libtheora.mk Make .debs
	$(call PACK,libtheora0,DEB_LIBTHEORA_V)
	$(call PACK,libtheora-dev,DEB_LIBTHEORA_V)

	# libtheora.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtheora{0,-dev}

.PHONY: libtheora libtheora-package
