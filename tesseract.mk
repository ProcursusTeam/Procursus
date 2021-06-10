ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += tesseract
TESSERACT_VERSION := 4.1.1
DEB_TESSERACT_V   ?= $(TESSERACT_VERSION)

###
# TODO:
# tesseract-lang package with the rest of the languages.
###

### Needs asciidoc

tesseract-setup: setup
	$(call GITHUB_ARCHIVE,tesseract-ocr,tesseract,$(TESSERACT_VERSION),$(TESSERACT_VERSION))
	$(call EXTRACT_TAR,tesseract-$(TESSERACT_VERSION).tar.gz,tesseract-$(TESSERACT_VERSION),tesseract)

ifneq ($(wildcard $(BUILD_WORK)/tesseract/.build_complete),)
tesseract:
	@echo "Using previously built tesseract."
else
tesseract: tesseract-setup leptonica libarchive curl
	cd $(BUILD_WORK)/tesseract && ./autogen.sh
	rm -f $(BUILD_WORK)/tesseract/VERSION # This, amazingly enough, makes compiling on macOS not work. (Non-case-sensitive)
	cd $(BUILD_WORK)/tesseract && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/tesseract
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_STAGE)/tesseract"
	+$(MAKE) -C $(BUILD_WORK)/tesseract install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/tesseract/.build_complete
endif

tesseract-package: tesseract-stage
	# tesseract.mk Package Structure
	rm -rf $(BUILD_DIST)/libtesseract4 $(BUILD_DIST)/libtesseract-dev $(BUILD_DIST)/tesseract-ocr
	mkdir -p \
		$(BUILD_DIST)/libtesseract-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/tesseract-ocr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libtesseract4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}

	# tesseract.mk Prep libtesseract-dev
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtesseract-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libtesseract.4.dylib) $(BUILD_DIST)/libtesseract-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tesseract.mk Prep tesseract-ocr
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tesseract-ocr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/tesseract-ocr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# tesseract.mk Prep libtesseract4
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtesseract.4.dylib $(BUILD_DIST)/libtesseract4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tesseract/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tessdata $(BUILD_DIST)/libtesseract4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	# Just bundle eng and osd with the library.
	wget -q -nc -P $(BUILD_DIST)/libtesseract4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tessdata \
		https://github.com/tesseract-ocr/tessdata_fast/raw/4.0.0/eng.traineddata \
		https://github.com/tesseract-ocr/tessdata_fast/raw/4.0.0/osd.traineddata

	# tesseract.mk Sign
	$(call SIGN,libtesseract4,general.xml)
	$(call SIGN,tesseract-ocr,general.xml)

	# tesseract.mk Make .debs
	$(call PACK,libtesseract-dev,DEB_TESSERACT_V)
	$(call PACK,tesseract-ocr,DEB_TESSERACT_V)
	$(call PACK,libtesseract4,DEB_TESSERACT_V)

	# tesseract.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtesseract4 $(BUILD_DIST)/libtesseract-dev $(BUILD_DIST)/tesseract-ocr

.PHONY: tesseract tesseract-package
