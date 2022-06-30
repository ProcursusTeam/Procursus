ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libxpresent
LIBXPRESENT_VERSION := 1.0.0
DEB_LIBXPRESENT_V   ?= $(LIBXPRESENT_VERSION)

libxpresent-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXpresent-$(LIBXPRESENT_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libXpresent-$(LIBXPRESENT_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libXpresent-$(LIBXPRESENT_VERSION).tar.bz2,libXpresent-$(LIBXPRESENT_VERSION),libxpresent)

ifneq ($(wildcard $(BUILD_WORK)/libxpresent/.build_complete),)
libxpresent:
	@echo "Using previously built libxpresent."
else
libxpresent: libxpresent-setup libx11 libxext util-macros libxfixes libxrandr
	cd $(BUILD_WORK)/libxpresent && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		  --enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxpresent
	+$(MAKE) -C $(BUILD_WORK)/libxpresent install \
		DESTDIR=$(BUILD_STAGE)/libxpresent
	$(call AFTER_BUILD,copy)
endif

libxpresent-package: libxpresent-stage
	# libxpresent.mk Package Structure
	rm -rf $(BUILD_DIST)/libxpresent{1,-dev}
	mkdir -p $(BUILD_DIST)/libxpresent{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxpresent.mk Prep libxpresent1
	cp -a $(BUILD_STAGE)/libxpresent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXpresent.1.dylib $(BUILD_DIST)/libxpresent1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxpresent.mk Prep libxpresent-dev
	cp -a $(BUILD_STAGE)/libxpresent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxpresent-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxpresent/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libXpresent.{dylib,a}} $(BUILD_DIST)/libxpresent-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxpresent.mk Sign
	$(call SIGN,libxpresent1,general.xml)

	# libxpresent.mk Make .debs
	$(call PACK,libxpresent1,DEB_LIBXPRESENT_V)
	$(call PACK,libxpresent-dev,DEB_LIBXPRESENT_V)

	# libxpresent.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxpresent{1,-dev}

.PHONY: libxpresent libxpresent-package
