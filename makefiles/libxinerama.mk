ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libxinerama
LIBXINERAMA_VERSION := 1.1.4
DEB_LIBXINERAMA_V   ?= $(LIBXINERAMA_VERSION)

libxinerama-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXinerama-$(LIBXINERAMA_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXinerama-$(LIBXINERAMA_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXinerama-$(LIBXINERAMA_VERSION).tar.gz,libXinerama-$(LIBXINERAMA_VERSION),libxinerama)

ifneq ($(wildcard $(BUILD_WORK)/libxinerama/.build_complete),)
libxinerama:
	@echo "Using previously built libxinerama."
else
libxinerama: libxinerama-setup libx11 libxext xorgproto
	cd $(BUILD_WORK)/libxinerama && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxinerama
	+$(MAKE) -C $(BUILD_WORK)/libxinerama install \
		DESTDIR=$(BUILD_STAGE)/libxinerama
	+$(MAKE) -C $(BUILD_WORK)/libxinerama install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxinerama/.build_complete
endif

libxinerama-package: libxinerama-stage
	# libxinerama.mk Package Structure
	rm -rf $(BUILD_DIST)/libxinerama{1,-dev}
	mkdir -p $(BUILD_DIST)/libxinerama1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxinerama-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxinerama.mk Prep libxinerama1
	cp -a $(BUILD_STAGE)/libxinerama/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXinerama.1*.dylib $(BUILD_DIST)/libxinerama1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxinerama.mk Prep libxinerama-dev
	cp -a $(BUILD_STAGE)/libxinerama/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXinerama.1*.dylib) $(BUILD_DIST)/libxinerama-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxinerama/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxinerama-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libxinerama.mk Sign
	$(call SIGN,libxinerama1,general.xml)

	# libxinerama.mk Make .debs
	$(call PACK,libxinerama1,DEB_LIBXINERAMA_V)
	$(call PACK,libxinerama-dev,DEB_LIBXINERAMA_V)

	# libxinerama.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxinerama{1,-dev}

.PHONY: libxinerama libxinerama-package
