ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += wimlib
WIMLIB_VERSION := 1.13.3
DEB_WIMLIB_V   ?= $(WIMLIB_VERSION)

wimlib-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://wimlib.net/downloads/wimlib-$(WIMLIB_VERSION).tar.gz
	$(call EXTRACT_TAR,wimlib-$(WIMLIB_VERSION).tar.gz,wimlib-$(WIMLIB_VERSION),wimlib)

ifneq ($(wildcard $(BUILD_WORK)/wimlib/.build_complete),)
wimlib:
	@echo "Using previously built wimlib."
else
wimlib: wimlib-setup openssl
	cd $(BUILD_WORK)/wimlib && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--disable-dependency-tracking \
		--without-fuse \
		--without-ntfs-3g \
		LIBXML2_CFLAGS=-I$(TARGET_SYSROOT)/usr/include \
		LIBXML2_LIBS="-L$(TARGET_SYSROOT)/usr/lib -lxml2"
	+$(MAKE) -C $(BUILD_WORK)/wimlib
	+$(MAKE) -C $(BUILD_WORK)/wimlib install \
		DESTDIR=$(BUILD_STAGE)/wimlib
	touch $(BUILD_WORK)/wimlib/.build_complete
endif

wimlib-package: wimlib-stage
	# wimlib.mk Package Structure
	rm -rf $(BUILD_DIST)/{libwim{15,-dev},wimtools}
	mkdir -p $(BUILD_DIST)/libwim{15,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/wimtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# wimlib.mk Prep wimtools
	cp -a $(BUILD_STAGE)/wimlib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/wimtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# wimlib.mk Prep libwim15
	cp -a $(BUILD_STAGE)/wimlib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwim.15.dylib $(BUILD_DIST)/libwim15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wimlib.mk Prep libwim-dev
	cp -a $(BUILD_STAGE)/wimlib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libwim.{a,dylib},pkgconfig} $(BUILD_DIST)/libwim-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# wimlib.mk Sign
	$(call SIGN,wimtools,general.xml)
	$(call SIGN,libwim15,general.xml)

	# wimlib.mk Make .debs
	$(call PACK,wimtools,DEB_WIMLIB_V)
	$(call PACK,libwim15,DEB_WIMLIB_V)
	$(call PACK,libwim-dev,DEB_WIMLIB_V)

	# wimlib.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libwim{15,-dev},wimtools}

.PHONY: wimlib wimlib-package
