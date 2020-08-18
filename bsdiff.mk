ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += bsdiff
BSDIFF_VERSION := 4.3
DEB_BSDIFF_V   ?= $(BSDIFF_VERSION)

bsdiff-setup: setup
	rm -rf $(BUILD_WORK)/bsdiff
	mkdir -p $(BUILD_WORK)/bsdiff
	cp -af bsdiff/* $(BUILD_WORK)/bsdiff

ifneq ($(wildcard $(BUILD_WORK)/bsdiff/.build_complete),)
bsdiff:
	@echo "Using previously built bsdiff."
else
bsdiff: bsdiff-setup bzip2
	cd $(BUILD_WORK)/bsdiff && ./autogen.sh && ./configure -C \
	--prefix=/usr \
	--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/bsdiff
	+$(MAKE) -C $(BUILD_WORK)/bsdiff install \
		DESTDIR=$(BUILD_STAGE)/bsdiff
	touch $(BUILD_WORK)/bsdiff/.build_complete
endif

bsdiff-package: bsdiff-stage
	# bsdiff.mk Package Structure
	rm -rf $(BUILD_DIST)/bsdiff
	mkdir -p $(BUILD_DIST)/bsdiff
	
	# bsdiff.mk Prep bsdiff
	cp -a $(BUILD_STAGE)/bsdiff/usr $(BUILD_DIST)/bsdiff
	
	# bsdiff.mk Sign
	$(call SIGN,bsdiff,general.xml)
	
	# bsdiff.mk Make .debs
	$(call PACK,bsdiff,DEB_BSDIFF_V)
	
	# bsdiff.mk Build cleanup
	rm -rf $(BUILD_DIST)/bsdiff

.PHONY: bsdiff bsdiff-package
