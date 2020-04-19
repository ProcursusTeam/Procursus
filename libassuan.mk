ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += libassuan
DOWNLOAD          += https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$(LIBASSUAN_VERSION).tar.bz2{,.sig}
LIBASSUAN_VERSION := 2.5.3
DEB_LIBASSUAN_V   ?= $(LIBASSUAN_VERSION)

libassuan-setup: setup
	$(call PGP_VERIFY,libassuan-$(LIBASSUAN_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libassuan-$(LIBASSUAN_VERSION).tar.bz2,libassuan-$(LIBASSUAN_VERSION),libassuan)

ifneq ($(wildcard $(BUILD_WORK)/libassuan/.build_complete),)
libassuan:
	@echo "Using previously built libassuan."
else
libassuan: libassuan-setup libgpg-error
	cd $(BUILD_WORK)/libassuan && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	+$(MAKE) -C $(BUILD_WORK)/libassuan
	+$(MAKE) -C $(BUILD_WORK)/libassuan install \
		DESTDIR=$(BUILD_STAGE)/libassuan
	+$(MAKE) -C $(BUILD_WORK)/libassuan install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libassuan/.build_complete
endif

libassuan-package: libassuan-stage
	# libassuan.mk Package Structure
	rm -rf $(BUILD_DIST)/libassuan
	mkdir -p $(BUILD_DIST)/libassuan
	
	# libassuan.mk Prep libassuan
	cp -a $(BUILD_STAGE)/libassuan/usr $(BUILD_DIST)/libassuan
	
	# libassuan.mk Sign
	$(call SIGN,libassuan,general.xml)
	
	# libassuan.mk Make .debs
	$(call PACK,libassuan,DEB_LIBASSUAN_V)
	
	# libassuan.mk Build cleanup
	rm -rf $(BUILD_DIST)/libassuan

.PHONY: libassuan libassuan-package

