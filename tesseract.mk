
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tesseract
TESSERACT_VERSION := 4.1.1
DEB_TESSERACT_V   ?= $(TESSERACT_VERSION)

tesseract-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/tesseract-$(TESSERACT_VERSION).tar.gz" ] && wget -q -nc -L -O$(BUILD_SOURCE)/tesseract-$(TESSERACT_VERSION).tar.gz \
		https://github.com/tesseract-ocr/tesseract/archive/$(TESSERACT_VERSION).tar.gz
	$(call EXTRACT_TAR,tesseract-$(TESSERACT_VERSION).tar.gz,tesseract-$(TESSERACT_VERSION),tesseract)

ifneq ($(wildcard $(BUILD_WORK)/tesseract/.build_complete),)
tesseract:
	@echo "Using previously built tesseract."
else
tesseract: tesseract-setup libarchive curl libpng16 libjpeg libtiff libleptonica
	cd $(BUILD_WORK)/tesseract && ./autogen.sh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/tesseract
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_STAGE)/tesseract"
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/tesseract/.build_complete
endif

tesseract-package: tesseract-stage
  # tesseract.mk Package Structure
	rm -rf $(BUILD_DIST)/tesseract
	mkdir -p $(BUILD_DIST)/tesseract

  # tesseract.mk Prep tesseract
	cp -a $(BUILD_STAGE)/tesseract/usr $(BUILD_DIST)/tesseract

  # tesseract.mk Sign
	$(call SIGN,tesseract,general.xml)

  # tesseract.mk Make .debs
	$(call PACK,tesseract,DEB_TESSERACT_V)

  # tesseract.mk Build cleanup
	rm -rf $(BUILD_DIST)/tesseract

.PHONY: tesseract tesseract-package
