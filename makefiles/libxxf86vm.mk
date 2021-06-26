ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxxf86vm
LIBXXF86VM_VERSION := 1.1.4
DEB_LIBXXF86VM_V   ?= $(LIBXXF86VM_VERSION)

libxxf86vm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/lib/libXxf86vm-$(LIBXXF86VM_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libXxf86vm-$(LIBXXF86VM_VERSION).tar.gz)
	$(call EXTRACT_TAR,libXxf86vm-$(LIBXXF86VM_VERSION).tar.gz,libXxf86vm-$(LIBXXF86VM_VERSION),libxxf86vm)

ifneq ($(wildcard $(BUILD_WORK)/libxxf86vm/.build_complete),)
libxxf86vm:
	@echo "Using previously built libxxf86vm."
else
libxxf86vm: libxxf86vm-setup xorgproto libx11 libxext
	cd $(BUILD_WORK)/libxxf86vm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-malloc0returnsnull=no
	+$(MAKE) -C $(BUILD_WORK)/libxxf86vm
	+$(MAKE) -C $(BUILD_WORK)/libxxf86vm install \
		DESTDIR=$(BUILD_STAGE)/libxxf86vm
	+$(MAKE) -C $(BUILD_WORK)/libxxf86vm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libxxf86vm/.build_complete
endif

libxxf86vm-package: libxxf86vm-stage
	# libxxf86vm.mk Package Structure
	rm -rf $(BUILD_DIST)/libxxf86vm{1,-dev}
	mkdir -p $(BUILD_DIST)/libxxf86vm1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxxf86vm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# libxxf86vm.mk Prep libxxf86vm1
	cp -a $(BUILD_STAGE)/libxxf86vm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libXxf86vm.1.dylib $(BUILD_DIST)/libxxf86vm1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxxf86vm.mk Prep libxxf86vm-dev
	cp -a $(BUILD_STAGE)/libxxf86vm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libXxf86vm{.a,.dylib},pkgconfig} $(BUILD_DIST)/libxxf86vm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxxf86vm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxxf86vm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxxf86vm.mk Sign
	$(call SIGN,libxxf86vm1,general.xml)

	# libxxf86vm.mk Make .debs
	$(call PACK,libxxf86vm1,DEB_LIBXXF86VM_V)
	$(call PACK,libxxf86vm-dev,DEB_LIBXXF86VM_V)

	# libxxf86vm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxxf86vm{1,-dev}

.PHONY: libxxf86vm libxxf86vm-package
