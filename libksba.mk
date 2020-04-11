ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

KSBA_VERSION := 1.3.5
DEB_KSBA_V   ?= $(KSBA_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libksba/.build_complete),)
libksba:
	@echo "Using previously built libksba."
else
libksba: setup libgpg-error
	cd $(BUILD_WORK)/libksba && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	+$(MAKE) -C $(BUILD_WORK)/libksba
	+$(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_STAGE)/libksba
	+$(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libksba/.build_complete
endif

libksba-package: libksba-stage
	# libksba.mk Package Structure
	rm -rf $(BUILD_DIST)/libksba
	mkdir -p $(BUILD_DIST)/libksba
	
	# libksba.mk Prep libksba
	$(FAKEROOT) cp -a $(BUILD_STAGE)/libksba/usr $(BUILD_DIST)/libksba
	
	# libksba.mk Sign
	$(call SIGN,libksba,general.xml)
	
	# libksba.mk Make .debs
	$(call PACK,libksba,DEB_KSBA_V)
	
	# libksba.mk Build cleanup
	rm -rf $(BUILD_DIST)/libksba

.PHONY: libksba libksba-package
