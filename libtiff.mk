ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libtiff
LIBTIFF_VERSION := 4.1.0
DEB_LIBTIFF_V   ?= $(LIBTIFF_VERSION)

libtiff-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://download.osgeo.org/libtiff/tiff-$(LIBTIFF_VERSION).tar.gz
	$(call EXTRACT_TAR,tiff-$(LIBTIFF_VERSION).tar.gz,tiff-$(LIBTIFF_VERSION),libtiff)

ifneq ($(wildcard $(BUILD_WORK)/libtiff/.build_complete),)
libtiff:
	@echo "Using previously built libtiff."
else
libtiff: libtiff-setup xz
	cd $(BUILD_WORK)/libtiff && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libtiff
	+$(MAKE) -C $(BUILD_WORK)/libtiff install \
		DESTDIR="$(BUILD_STAGE)/libtiff"
	+$(MAKE) -C $(BUILD_WORK)/libtiff install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtiff/.build_complete
endif

libtiff-package: libtiff-stage
  # libtiff.mk Package Structure
	rm -rf $(BUILD_DIST)/libtiff
	mkdir -p $(BUILD_DIST)/libtiff

  # libtiff.mk Prep libtiff
	cp -a $(BUILD_STAGE)/libtiff/usr $(BUILD_DIST)/libtiff

  # libtiff.mk Sign
	$(call SIGN,libtiff,general.xml)

  # libtiff.mk Make .debs
	$(call PACK,libtiff,DEB_LIBTIFF_V)

  # libtiff.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtiff

.PHONY: libtiff libtiff-package
