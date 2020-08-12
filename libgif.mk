
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libgif
LIBGIF_VERSION := 5.2.1
DEB_LIBGIF_V   ?= $(LIBGIF_VERSION)

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
	cd $(BUILD_WORK)/libgif
	+$(MAKE) -C $(BUILD_WORK)/libgif all
	+$(MAKE) -C $(BUILD_WORK)/libgif install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/libgif
	+$(MAKE) -C $(BUILD_WORK)/libgif install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgif/.build_complete
endif

libgif-package: libgif-stage
  # libgif.mk Package Structure
	rm -rf $(BUILD_DIST)/libgif
	mkdir -p $(BUILD_DIST)/libgif

  # libgif.mk Prep libgif
	cp -a $(BUILD_STAGE)/libgif/usr $(BUILD_DIST)/libgif

  # libgif.mk Sign
	$(call SIGN,libgif,general.xml)

  # libgif.mk Make .debs
	$(call PACK,libgif,DEB_LIBGIF_V)

  # libgif.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgif

.PHONY: libgif libgif-package
