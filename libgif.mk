
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libgif
LIBGIF_VERSION := 5.2.1
DEB_LIBGIF_V   ?= $(LIBGIF_VERSION)-1

libgif-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://sourceforge.net/projects/giflib/files/giflib-$(LIBGIF_VERSION).tar.gz
	$(call EXTRACT_TAR,giflib-$(LIBGIF_VERSION).tar.gz,giflib-$(LIBGIF_VERSION),libgif)
	$(call DO_PATCH,libgif,libgif,-p0)

ifneq ($(wildcard $(BUILD_WORK)/libgif/.build_complete),)
libgif:
	@echo "Using previously built libgif."
else
libgif: libgif-setup
	+$(MAKE) -C $(BUILD_WORK)/libgif all -j1 \
		PREFIX=/usr \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/libgif install -j1 \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/libgif
	+$(MAKE) -C $(BUILD_WORK)/libgif install -j1 \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgif/.build_complete
endif

libgif-package: libgif-stage
  # libgif.mk Package Structure
	rm -rf $(BUILD_DIST)/{giflib-tools,libgif{7,-dev}}
	mkdir -p \
		$(BUILD_DIST)/giflib-tools/usr \
		$(BUILD_DIST)/libgif{7,-dev}/usr/lib

  # libgif.mk Prep giflib-tools
	cp -a $(BUILD_STAGE)/libgif/usr/bin $(BUILD_DIST)/giflib-tools/usr

  # libgif.mk Prep libgif-dev
	cp -a $(BUILD_STAGE)/libgif/usr/include $(BUILD_DIST)/libgif-dev/usr
	cp -a $(BUILD_STAGE)/libgif/usr/lib/libgif.{a,dylib} $(BUILD_DIST)/libgif-dev/usr/lib

  # libgif.mk Prep libgif7
	cp -a $(BUILD_STAGE)/libgif/usr/lib/libgif.7*.dylib $(BUILD_DIST)/libgif7/usr/lib

  # libgif.mk Sign
	$(call SIGN,giflib-tools,general.xml)
	$(call SIGN,libgif-dev,general.xml)
	$(call SIGN,libgif7,general.xml)

  # libgif.mk Make .debs
	$(call PACK,giflib-tools,DEB_LIBGIF_V)
	$(call PACK,libgif-dev,DEB_LIBGIF_V)
	$(call PACK,libgif7,DEB_LIBGIF_V)

  # libgif.mk Build cleanup
	rm -rf $(BUILD_DIST)/{giflib-tools,libgif{7,-dev}}

.PHONY: libgif libgif-package
