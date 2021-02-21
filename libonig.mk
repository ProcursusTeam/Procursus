ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libonig
LIBONIG_VERSION := 6.9.6
DEB_LIBONIG_V   ?= $(LIBONIG_VERSION)

libonig-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/kkos/oniguruma/releases/download/v$(LIBONIG_VERSION)/onig-$(LIBONIG_VERSION).tar.gz
	$(call EXTRACT_TAR,onig-$(LIBONIG_VERSION).tar.gz,onig-$(LIBONIG_VERSION),libonig)

ifneq ($(wildcard $(BUILD_WORK)/libonig/.build_complete),)
libonig:
	@echo "Using previously built libonig."
else
libonig: libonig-setup
	cd $(BUILD_WORK)/libonig && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libonig install \
		DESTDIR=$(BUILD_STAGE)/libonig
	+$(MAKE) -C $(BUILD_WORK)/libonig install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libonig/.build_complete
endif

libonig-package: libonig-stage
	# libonig.mk Package Structure
	rm -rf $(BUILD_DIST)/libonig{5,-dev}
	mkdir -p $(BUILD_DIST)/libonig5/usr/lib \
			$(BUILD_DIST)/libonig-dev/usr/{include,lib/pkgconfig}

	# libonig.mk Prep libonig5
	cp -a $(BUILD_STAGE)/libonig/usr/lib/libonig.5.dylib $(BUILD_DIST)/libonig5/usr/lib

	# libonig.mk Prep libonig-dev
	cp -a $(BUILD_STAGE)/libonig/usr/include/onig{gnu.h,uruma.h} $(BUILD_DIST)/libonig-dev/usr/include
	cp -a $(BUILD_STAGE)/libonig/usr/lib/libonig.{a,dylib} $(BUILD_DIST)/libonig-dev/usr/lib
	cp -a $(BUILD_STAGE)/libonig/usr/lib/pkgconfig/oniguruma.pc $(BUILD_DIST)/libonig-dev/usr/lib/pkgconfig

	# libonig.mk Sign
	$(call SIGN,libonig5,general.xml)

	# libonig.mk Make .debs
	$(call PACK,libonig5,DEB_LIBONIG_V)
	$(call PACK,libonig-dev,DEB_LIBONIG_V)

	# libonig.mk Build cleanup
	rm -rf $(BUILD_DIST)/libonig{5,-dev}

.PHONY: libonig libonig-package
