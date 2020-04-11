ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBGPG-ERROR_VERSION := 1.37
DEB_LIBGPG-ERROR_V   ?= $(LIBGPG-ERROR_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libgpg-error/.build_complete),)
libgpg-error:
	@echo "Using previously built libgpg-error."
else
libgpg-error: setup
	$(SED) -i '/{"armv7-unknown-linux-gnueabihf"  },/a \ \ \ \ {"$(GNU_HOST_TRIPLE)",  "$(GNU_HOST_TRIPLE)" },' $(BUILD_WORK)/libgpg-error/src/mkheader.c
	cd $(BUILD_WORK)/libgpg-error && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-nls
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_STAGE)/libgpg-error
	+$(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_BASE)	
	touch $(BUILD_WORK)/libgpg-error/.build_complete
endif

libgpg-error-package: libgpg-error-stage
	# libgpg-error.mk Package Structure
	rm -rf $(BUILD_DIST)/libgpg-error
	mkdir -p $(BUILD_DIST)/libgpg-error
	
	# libgpg-error.mk Prep libgpg-error
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libgpg-error/usr $(BUILD_DIST)/libgpg-error
	
	# libgpg-error.mk Sign
	$(call SIGN,libgpg-error,general.xml)
	
	# libgpg-error.mk Make .debs
	$(call PACK,libgpg-error,DEB_LIBGPG-ERROR_V)
	
	# libgpg-error.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgpg-error

.PHONY: libgpg-error libgpg-error-package