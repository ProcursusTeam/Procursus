ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += binaryen
BINARYEN_VERSION := 101
DEB_BINARYEN_V   ?= $(BINARYEN_VERSION)

binaryen-setup: setup
	$(call GITHUB_ARCHIVE,WebAssembly,binaryen,version_$(BINARYEN_VERSION),version_$(BINARYEN_VERSION))
	$(call EXTRACT_TAR,binaryen-version_$(BINARYEN_VERSION).tar.gz,binaryen-version_$(BINARYEN_VERSION),binaryen)
	$(call DO_PATCH,binaryen,binaryen,-p1)
	mkdir -p $(BUILD_WORK)/binaryen/build

ifneq ($(wildcard $(BUILD_WORK)/binaryen/.build_complete),)
binaryen:
	@echo "Using previously built binaryen."
else
binaryen: binaryen-setup
	cd $(BUILD_WORK)/binaryen/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/binaryen/build
	+$(MAKE) -C $(BUILD_WORK)/binaryen/build install \
		DESTDIR="$(BUILD_STAGE)/binaryen"
	touch $(BUILD_WORK)/binaryen/.build_complete
endif

binaryen-package: binaryen-stage
	# binaryen.mk Package Structure
	rm -rf $(BUILD_DIST)/binaryen
	
	# binaryen.mk Prep binaryen
	cp -a $(BUILD_STAGE)/binaryen $(BUILD_DIST)
	
	# binaryen.mk Sign
	$(call SIGN,binaryen,general.xml)
	
	# binaryen.mk Make .debs
	$(call PACK,binaryen,DEB_BINARYEN_V)
	
	# binaryen.mk Build cleanup
	rm -rf $(BUILD_DIST)/binaryen

.PHONY: binaryen binaryen-package
