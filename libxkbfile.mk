ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxkbfile
LIBXKBFILE_VERSION := 1.1.0
DEB_LIBXKBFILE_V   ?= $(LIBXKBFILE_VERSION)

libxkbfile-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libxkbfile-$(LIBXKBFILE_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libxkbfile-$(LIBXKBFILE_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libxkbfile-$(LIBXKBFILE_VERSION).tar.bz2,libxkbfile-$(LIBXKBFILE_VERSION),libxkbfile)

ifneq ($(wildcard $(BUILD_WORK)/libxkbfile/.build_complete),)
libxkbfile:
	@echo "Using previously built libxkbfile."
else
libxkbfile: libxkbfile-setup libx11
	cd $(BUILD_WORK)/libxkbfile && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxkbfile
	+$(MAKE) -C $(BUILD_WORK)/libxkbfile install \
		DESTDIR=$(BUILD_STAGE)/libxkbfile
	+$(MAKE) -C $(BUILD_WORK)/libxkbfile install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxkbfile/.build_complete
endif

libxkbfile-package: libxkbfile-stage
	# libxkbfile.mk Package Structure
	rm -rf $(BUILD_DIST)/libxkbfile{1,-dev}
	mkdir -p $(BUILD_DIST)/libxkbfile1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxkbfile-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libxkbfile.mk Prep libxkbfile1
	cp -a $(BUILD_STAGE)/libxkbfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxkbfile.1.dylib $(BUILD_DIST)/libxkbfile1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxkbfile.mk Prep libxkbfile-dev
	cp -a $(BUILD_STAGE)/libxkbfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libxkbfile{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxkbfile-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxkbfile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxkbfile-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxkbfile.mk Sign
	$(call SIGN,libxkbfile1,general.xml)

	# libxkbfile.mk Make .debs
	$(call PACK,libxkbfile1,DEB_LIBXKBFILE_V)
	$(call PACK,libxkbfile-dev,DEB_LIBXKBFILE_V)

	# libxkbfile.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxkbfile{1,-dev}

.PHONY: libxkbfile libxkbfile-package
