ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxres
LIBXRES_VERSION := 1.2.1
DEB_LIBXRES_V   ?= $(LIBXRES_VERSION)

libxres-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/lib/libXres-$(LIBXRES_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXres-$(LIBXRES_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXres-$(LIBXRES_VERSION).tar.gz,libXres-$(LIBXRES_VERSION),libxres)

ifneq ($(wildcard $(BUILD_WORK)/libxres/.build_complete),)
libxres:
	@echo "Using previously built libxres."
else
libxres: libxres-setup libx11 libxext
	cd $(BUILD_WORK)/libxres && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxres
	+$(MAKE) -C $(BUILD_WORK)/libxres install \
		DESTDIR=$(BUILD_STAGE)/libxres
	+$(MAKE) -C $(BUILD_WORK)/libxres install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxres/.build_complete
endif

libxres-package: libxres-stage
	# libxres.mk Package Structure
	rm -rf $(BUILD_DIST)/libxres{1,-dev}
	mkdir -p $(BUILD_DIST)/libxres1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxres-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxres.mk Prep libxres1
	cp -a $(BUILD_STAGE)/libxres/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXRes.1*.dylib $(BUILD_DIST)/libxres1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxres.mk Prep libxres-dev
	cp -a $(BUILD_STAGE)/libxres/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libXRes.1*.dylib) $(BUILD_DIST)/libxres-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxres/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libxres-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libxres.mk Sign
	$(call SIGN,libxres1,general.xml)

	# libxres.mk Make .debs
	$(call PACK,libxres1,DEB_LIBXRES_V)
	$(call PACK,libxres-dev,DEB_LIBXRES_V)

	# libxres.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxres{1,-dev}

.PHONY: libxres libxres-package
