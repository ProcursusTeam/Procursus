ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libxpm
LIBXPM_VERSION := 3.5.13
DEB_LIBXPM_V   ?= $(LIBXPM_VERSION)

libxpm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXpm-$(LIBXPM_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXpm-$(LIBXPM_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXpm-$(LIBXPM_VERSION).tar.bz2,libXpm-$(LIBXPM_VERSION),libxpm)

ifneq ($(wildcard $(BUILD_WORK)/libxpm/.build_complete),)
libxpm:
	@echo "Using previously built libxpm."
else
libxpm: libxpm-setup libx11 xorgproto libxt libxext gettext
	cd $(BUILD_WORK)/libxpm && unset CPP CPPFLAGS && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxpm
	+$(MAKE) -C $(BUILD_WORK)/libxpm install \
		DESTDIR=$(BUILD_STAGE)/libxpm
	+$(MAKE) -C $(BUILD_WORK)/libxpm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxpm/.build_complete
endif

libxpm-package: libxpm-stage
	# libxpm.mk Package Structure
	rm -rf $(BUILD_DIST)/libxpm{4,-dev} $(BUILD_DIST)/libxpm $(BUILD_DIST)/xpmutils
	mkdir -p $(BUILD_DIST)/libxpm4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxpm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/xpmutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxpm.mk Prep libxpm4
	cp -a $(BUILD_STAGE)/libxpm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXpm.4.dylib $(BUILD_DIST)/libxpm4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxpm.mk Prep libxpm-dev
	cp -a $(BUILD_STAGE)/libxpm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXpm.4.dylib) $(BUILD_DIST)/libxpm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxpm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxpm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxpm.mk xpmutils
	cp -a $(BUILD_STAGE)/libxpm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/xpmutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxpm.mk Sign
	$(call SIGN,libxpm4,general.xml)
	$(call SIGN,xpmutils,general.xml)

	# libxpm.mk Make .debs
	$(call PACK,libxpm4,DEB_LIBXPM_V)
	$(call PACK,libxpm-dev,DEB_LIBXPM_V)
	$(call PACK,xpmutils,DEB_LIBXPM_V)

	# libxpm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxpm{4,-dev} $(BUILD_DIST)/xpmutils

.PHONY: libxpm libxpm-package
