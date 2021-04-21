ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxtst
LIBXTST_VERSION := 1.2.3
DEB_LIBXTST_V   ?= $(LIBXTST_VERSION)

libxtst-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXtst-$(LIBXTST_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXtst-$(LIBXTST_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXtst-$(LIBXTST_VERSION).tar.gz,libXtst-$(LIBXTST_VERSION),libxtst)

ifneq ($(wildcard $(BUILD_WORK)/libxtst/.build_complete),)
libxtst:
	@echo "Using previously built libxtst."
else
libxtst: libxtst-setup xorgproto libx11 libxi
	cd $(BUILD_WORK)/libxtst && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libxtst
	+$(MAKE) -C $(BUILD_WORK)/libxtst install \
		DESTDIR=$(BUILD_STAGE)/libxtst
	+$(MAKE) -C $(BUILD_WORK)/libxtst install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxtst/.build_complete
endif

libxtst-package: libxtst-stage
	# libxtst.mk Package Structure
	rm -rf $(BUILD_DIST)/libxtst{6,-dev,-doc}
	mkdir -p $(BUILD_DIST)/libxtst6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxtst-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libxtst-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxtst.mk Prep libxtst6
	cp -a $(BUILD_STAGE)/libxtst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXtst.6.dylib $(BUILD_DIST)/libxtst6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxtst.mk Prep libxtst-dev
	cp -a $(BUILD_STAGE)/libxtst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXtst{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxtst-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxtst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxtst-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxtst.mk Prep libxtst-doc
	cp -a $(BUILD_STAGE)/libxtst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libxtst-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxtst.mk Sign
	$(call SIGN,libxtst6,general.xml)

	# libxtst.mk Make .debs
	$(call PACK,libxtst6,DEB_LIBXTST_V)
	$(call PACK,libxtst-dev,DEB_LIBXTST_V)
	$(call PACK,libxtst-doc,DEB_LIBXTST_V)

	# libxtst.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxtst{6,-dev,-doc}

.PHONY: libxtst libxtst-package
