
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libleptonica
LIBLEPTONICA_VERSION := 1.79.0
DEB_LIBLEPTONICA_V   ?= $(LIBLEPTONICA_VERSION)

libleptonica-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		http://www.libleptonica.org/source/leptonica-$(LIBLEPTONICA_VERSION).tar.gz
	$(call EXTRACT_TAR,leptonica-$(LIBLEPTONICA_VERSION).tar.gz,leptonica-$(LIBLEPTONICA_VERSION),libleptonica)

ifneq ($(wildcard $(BUILD_WORK)/libleptonica/.build_complete),)
libleptonica:
	@echo "Using previously built libleptonica."
else
libleptonica: libleptonica-setup libjpeg libpng16
	cd $(BUILD_WORK)/libleptonica && ./autogen.sh && ./configure -C \
		--without-libopenjpeg \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libleptonica
	+$(MAKE) -C $(BUILD_WORK)/libleptonica install \
		DESTDIR="$(BUILD_STAGE)/libleptonica"
	+$(MAKE) -C $(BUILD_WORK)/libleptonica install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libleptonica/.build_complete
endif

libleptonica-package: libleptonica-stage
  # libleptonica.mk Package Structure
	rm -rf $(BUILD_DIST)/libleptonica
	mkdir -p $(BUILD_DIST)/libleptonica

  # libleptonica.mk Prep libleptonica
	cp -a $(BUILD_STAGE)/libleptonica/usr $(BUILD_DIST)/libleptonica

  # libleptonica.mk Sign
	$(call SIGN,libleptonica,general.xml)

  # libleptonica.mk Make .debs
	$(call PACK,libleptonica,DEB_LIBLEPTONICA_V)

  # libleptonica.mk Build cleanup
	rm -rf $(BUILD_DIST)/libleptonica

.PHONY: libleptonica libleptonica-package
