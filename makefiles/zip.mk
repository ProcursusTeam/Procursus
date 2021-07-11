ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += zip
ZIP_VERSION  := 3.0
DEBIAN_ZIP_V := $(ZIP_VERSION)-12
DEB_ZIP_V    ?= $(DEBIAN_ZIP_V)

zip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://deb.debian.org/debian/pool/main/z/zip/zip_$(ZIP_VERSION).orig.tar.gz \
		https://deb.debian.org/debian/pool/main/z/zip/zip_$(DEBIAN_ZIP_V).debian.tar.xz
	$(call EXTRACT_TAR,zip_$(ZIP_VERSION).orig.tar.gz,zip30,zip)
	$(call EXTRACT_TAR,zip_$(DEBIAN_ZIP_V).debian.tar.xz,debian/patches,$(BUILD_PATCH)/zip-$(ZIP_VERSION))
	rm $(BUILD_PATCH)/zip-$(ZIP_VERSION)/series
	rm -rf $(BUILD_WORK)/debian
	$(call DO_PATCH,zip-$(ZIP_VERSION),zip,-p1)

ifneq ($(wildcard $(BUILD_WORK)/zip/.build_complete),)
zip:
	@echo "Using previously built zip."
else
zip: zip-setup
	+cd $(BUILD_WORK)/zip && $(MAKE) -f unix/Makefile install \
		prefix=$(BUILD_STAGE)/zip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS) -I. -DUNIX -DBZIP2_SUPPORT" \
		LFLAGS2="-lbz2 $(CFLAGS)" \
		MANDIR="$(BUILD_STAGE)/zip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1"
	touch $(BUILD_WORK)/zip/.build_complete
endif

zip-package: zip-stage
	# zip.mk Package Structure
	rm -rf $(BUILD_DIST)/zip
	mkdir -p $(BUILD_DIST)/zip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# zip.mk Prep zip
	cp -a $(BUILD_STAGE)/zip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/zip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# zip.mk Sign
	$(call SIGN,zip,general.xml)

	# zip.mk Make .debs
	$(call PACK,zip,DEB_ZIP_V)

	# zip.mk Build cleanup
	rm -rf $(BUILD_DIST)/zip

.PHONY: zip zip-package
