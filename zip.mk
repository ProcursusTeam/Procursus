ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ZIP_VERSION  := 3.0
DEBIAN_ZIP_V := $(ZIP_VERSION)-11
DEB_ZIP_V    ?= $(DEBIAN_ZIP_V)

ifneq ($(wildcard $(BUILD_WORK)/zip/.build_complete),)
zip:
	@echo "Using previously built zip."
else
zip: setup
	cd $(BUILD_WORK)/zip && $(MAKE) -f unix/Makefile install \
		prefix=$(BUILD_STAGE)/zip/usr \
		CC=$(CC) \
		CPP="$(CXX)" \
		CFLAGS="$(CFLAGS) -I. -DUNIX -DBZIP2_SUPPORT" \
		LFLAGS2="-lbz2"
	touch $(BUILD_WORK)/zip/.build_complete
endif

zip-package: zip-stage
	# zip.mk Package Structure
	rm -rf $(BUILD_DIST)/zip
	mkdir -p $(BUILD_DIST)/zip
	
	# zip.mk Prep zip
	$(FAKEROOT) cp -a $(BUILD_STAGE)/zip/usr $(BUILD_DIST)/zip
	$(FAKEROOT) rm -rf $(BUILD_DIST)/zip/usr/man
	
	# zip.mk Sign
	$(call SIGN,zip,general.xml)
	
	# zip.mk Make .debs
	$(call PACK,zip,DEB_ZIP_V)
	
	# zip.mk Build cleanup
	rm -rf $(BUILD_DIST)/zip

.PHONY: zip zip-package
