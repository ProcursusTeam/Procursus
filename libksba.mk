ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += libksba
DOWNLOAD      += https://gnupg.org/ftp/gcrypt/libksba/libksba-$(KSBA_VERSION).tar.bz2{,.sig}
KSBA_VERSION  := 1.3.5
DEB_KSBA_V    ?= $(KSBA_VERSION)

libksba-setup: setup
	$(call PGP_VERIFY,libksba-$(KSBA_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libksba-$(KSBA_VERSION).tar.bz2,libksba-$(KSBA_VERSION),libksba)

ifneq ($(wildcard $(BUILD_WORK)/libksba/.build_complete),)
libksba:
	@echo "Using previously built libksba."
else
libksba: libksba-setup libgpg-error
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
	cp -a $(BUILD_STAGE)/libksba/usr $(BUILD_DIST)/libksba
	
	# libksba.mk Sign
	$(call SIGN,libksba,general.xml)
	
	# libksba.mk Make .debs
	$(call PACK,libksba,DEB_KSBA_V)
	
	# libksba.mk Build cleanup
	rm -rf $(BUILD_DIST)/libksba

.PHONY: libksba libksba-package
