ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DIFFUTILS_VERSION := 3.7
DEB_DIFFUTILS_V   ?= $(DIFFUTILS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/diffutils/.build_complete),)
diffutils:
	@echo "Using previously built diffutils."
else
diffutils: setup
	cd $(BUILD_WORK)/diffutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	$(MAKE) -C $(BUILD_WORK)/diffutils
	$(MAKE) -C $(BUILD_WORK)/diffutils install \
		DESTDIR=$(BUILD_STAGE)/diffutils
	touch $(BUILD_WORK)/diffutils/.build_complete
endif

diffutils-package: diffutils-stage
	# diffutils.mk Package Structure
	rm -rf $(BUILD_DIST)/diffutils
	mkdir -p $(BUILD_DIST)/diffutils
	
	# diffutils.mk Prep diffutils
	$(FAKEROOT) cp -a $(BUILD_STAGE)/diffutils/usr $(BUILD_DIST)/diffutils
	
	# diffutils.mk Sign
	$(call SIGN,diffutils,general.xml)
	
	# diffutils.mk Make .debs
	$(call PACK,diffutils,DEB_DIFFUTILS_V)
	
	# diffutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/diffutils

.PHONY: diffutils diffutils-package
