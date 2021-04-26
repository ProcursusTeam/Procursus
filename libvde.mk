ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libvde
LIBVDE_VERSION := 2.3.2
DEB_LIBVDE_V   ?= $(LIBVDE_VERSION)

libvde-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/vde/vde2/$(LIBVDE_VERSION)/vde2-$(LIBVDE_VERSION).tar.gz
	$(call EXTRACT_TAR,vde2-$(LIBVDE_VERSION).tar.gz,vde2-$(LIBVDE_VERSION),libvde)
	$(call DO_PATCH,vde2,libvde,-p1)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/libvde

ifneq ($(wildcard $(BUILD_WORK)/libvde/.build_complete),)
libvde:
	@echo "Using previously built libvde."
else
libvde: libvde-setup openssl
	cd $(BUILD_WORK)/libvde && unset MACOSX_DEPLOYMENT_TARGET && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-python \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	unset MAKEFLAGS && $(MAKE) -C $(BUILD_WORK)/libvde install \
		DESTDIR="$(BUILD_STAGE)/libvde"
	+$(MAKE) -C $(BUILD_WORK)/libvde install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libvde/.build_complete
endif

libvde-package: libvde-stage
	# libvde.mk Package Structure
	rm -rf $(BUILD_DIST)/libvde{0,-dev} $(BUILD_DIST)/libvdeplug{2,-dev} $(BUILD_DIST)/vde2{,-cryptcab}
	mkdir -p $(BUILD_DIST)/libvde0/{etc/vde2,usr/lib} \
	$(BUILD_DIST)/libvde-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig} \
	$(BUILD_DIST)/libvdeplug2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
	$(BUILD_DIST)/libvdeplug-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig} \
	$(BUILD_DIST)/vde2/{etc/vde2,usr/lib/vde2/vde_l3} \
	$(BUILD_DIST)/vde2-cryptcab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# libvde.mk Prep libvde0
	cp -a $(BUILD_STAGE)/libvde/etc/vde2/libvdemgmt $(BUILD_DIST)/libvde0/etc/vde2
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libvdehist,libvdemgmt,libvdesnmp}.0.dylib $(BUILD_DIST)/libvde0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libvde.mk Prep libvde-dev
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libvdehist,libvdemgmt,libvdesnmp}.{a,dylib} $(BUILD_DIST)/libvde-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/{vdehist,vdemgmt,vdesnmp}.pc $(BUILD_DIST)/libvde-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{libvdehist,libvdemgmt,libvdesnmp}.h $(BUILD_DIST)/libvde-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libvde.mk Prep libvdeplug2
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvdeplug.2.dylib $(BUILD_DIST)/libvdeplug2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libvde.mk Prep libvdeplug-dev
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvdeplug.{a,dylib} $(BUILD_DIST)/libvdeplug-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/vdeplug.pc $(BUILD_DIST)/libvdeplug-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libvdeplug{,_dyn}.h $(BUILD_DIST)/libvdeplug-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libvde.mk Prep vde2
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vde2/vde_l3/{{b,p}fifo,tbf}.so $(BUILD_DIST)/vde2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vde2/vde_l3
	cp -a $(BUILD_STAGE)/libvde/etc/vde2/vdecmd $(BUILD_DIST)/vde2/etc/vde2
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/vde2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -f $(BUILD_DIST)/vde2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vde{cmd,kvm,qemu,_cryptcab}
	rm -f $(BUILD_DIST)/vde2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/vde{cmd,kvm,qemu,_cryptcab}.1

	# libvde.mk Prep vde2-cryptcab
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vde_cryptcab $(BUILD_DIST)/vde2-cryptcab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libvde/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/vde_cryptcab.1 $(BUILD_DIST)/vde2-cryptcab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# libvde.mk Sign
	$(call SIGN,libvde0,general.xml)
	$(call SIGN,libvdeplug2,general.xml)
	$(call SIGN,vde2,general.xml)
	$(call SIGN,vde2-cryptcab,general.xml)

	# libvde.mk Make .debs
	$(call PACK,libvde0,DEB_LIBVDE_V)
	$(call PACK,libvde-dev,DEB_LIBVDE_V)
	$(call PACK,libvdeplug2,DEB_LIBVDE_V)
	$(call PACK,libvdeplug-dev,DEB_LIBVDE_V)
	$(call PACK,vde2,DEB_LIBVDE_V)
	$(call PACK,vde2-cryptcab,DEB_LIBVDE_V)

	# libvde.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvde{0,-dev} $(BUILD_DIST)/libvdeplug{2,-dev} $(BUILD_DIST)/vde2{,-cryptcab}

.PHONY: libvde libvde-package