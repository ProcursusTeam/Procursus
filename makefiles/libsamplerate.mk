ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libsamplerate
LIBSAMPLERATE_VERSION := 0.1.9
DEB_LIBSAMPLERATE_V   ?= $(LIBSAMPLERATE_VERSION)

libsamplerate-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://www.mega-nerd.com/SRC/libsamplerate-$(LIBSAMPLERATE_VERSION).tar.gz
	$(call EXTRACT_TAR,libsamplerate-$(LIBSAMPLERATE_VERSION).tar.gz,libsamplerate-$(LIBSAMPLERATE_VERSION),libsamplerate)

ifneq ($(wildcard $(BUILD_WORK)/libsamplerate/.build_complete),)
libsamplerate:
	@echo "Using previously built libsamplerate."
else
libsamplerate: libsamplerate-setup
	cd $(BUILD_WORK)/libsamplerate && autoreconf -fi
	cd $(BUILD_WORK)/libsamplerate && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libsamplerate \
		SUBDIRS="M4 src"
	+$(MAKE) -C $(BUILD_WORK)/libsamplerate install \
		SUBDIRS="M4 src" \
		DESTDIR=$(BUILD_STAGE)/libsamplerate
	+$(MAKE) -C $(BUILD_WORK)/libsamplerate install \
		SUBDIRS="M4 src" \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsamplerate/.build_complete
endif

libsamplerate-package: libsamplerate-stage
	# libsamplerate.mk Package Structure
	rm -rf $(BUILD_DIST)/libsamplerate0{,-dev}
	mkdir -p $(BUILD_DIST)/libsamplerate0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsamplerate.mk Prep libsamplerate0
	cp -a $(BUILD_STAGE)/libsamplerate/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsamplerate.0.dylib $(BUILD_DIST)/libsamplerate0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsamplerate.mk Prep libsamplerate0-dev
	cp -a $(BUILD_STAGE)/libsamplerate/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libsamplerate.{dylib,a}} $(BUILD_DIST)/libsamplerate0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsamplerate/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsamplerate0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsamplerate.mk Sign
	$(call SIGN,libsamplerate0,general.xml)

	# libsamplerate.mk Make .debs
	$(call PACK,libsamplerate0,DEB_LIBSAMPLERATE_V)
	$(call PACK,libsamplerate0-dev,DEB_LIBSAMPLERATE_V)

	# libsamplerate.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsamplerate0{,-dev}

.PHONY: libsamplerate libsamplerate-package
