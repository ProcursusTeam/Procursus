ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DARWINTOOLS_VERSION := 1.2
DEB_DARWINTOOLS_V   ?= $(DARWINTOOLS_VERSION)

ifneq ($(wildcard darwintools/.build_complete),)
darwintools:
	@echo "Using previously built darwintools."
else
darwintools: setup
	cd darwintools && make
	mkdir -p $(BUILD_STAGE)/darwintools/usr/{bin,libexec/cydia}
	cp darwintools/sw_vers $(BUILD_STAGE)/darwintools/usr/bin
	cp darwintools/firmware $(BUILD_STAGE)/darwintools/usr/libexec
	cd $(BUILD_STAGE)/darwintools/usr/libexec && ln -s firmware firmware.sh 
	chmod 0755 $(BUILD_STAGE)/darwintools/usr/libexec/firmware
	touch darwintools/.build_complete
endif

darwintools-package: darwintools-stage
	# darwintools.mk Package Structure
	rm -rf $(BUILD_DIST)/darwintools
	mkdir -p $(BUILD_DIST)/darwintools
	
	# darwintools.mk Prep darwintools
	$(FAKEROOT) cp -a $(BUILD_STAGE)/darwintools/usr $(BUILD_DIST)/darwintools
	
	# darwintools.mk Sign
	$(call SIGN,darwintools,general.xml)
	
	# darwintools.mk Make .debs
	$(call PACK,darwintools,DEB_DARWINTOOLS_V)
	
	# darwintools.mk Build cleanup
	rm -rf $(BUILD_DIST)/darwintools

.PHONY: darwintools darwintools-package
