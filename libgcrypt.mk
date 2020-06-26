ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += libgcrypt
LIBGCRYPT_VERSION := 1.8.5
DEB_LIBGCRYPT_V   ?= $(LIBGCRYPT_VERSION)

libgcrypt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libgcrypt-$(LIBGCRYPT_VERSION).tar.bz2,libgcrypt-$(LIBGCRYPT_VERSION),libgcrypt)
	for ASM in $(BUILD_WORK)/libgcrypt/mpi/aarch64/*.S; do \
		$(SED) -i '/.type/d' $$ASM; \
		$(SED) -i '/.size/d' $$ASM; \
		$(SED) -i 's/_gcry/__gcry/g' $$ASM; \
	done

ifneq ($(wildcard $(BUILD_WORK)/libgcrypt/.build_complete),)
libgcrypt:
	@echo "Using previously built libgcrypt."
else
libgcrypt: libgcrypt-setup libgpg-error
	cd $(BUILD_WORK)/libgcrypt && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	+$(MAKE) -C $(BUILD_WORK)/libgcrypt
	+$(MAKE) -C $(BUILD_WORK)/libgcrypt install \
		DESTDIR=$(BUILD_STAGE)/libgcrypt
	+$(MAKE) -C $(BUILD_WORK)/libgcrypt install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgcrypt/.build_complete
endif

libgcrypt-package: libgcrypt-stage
	# libgcrypt.mk Package Structure
	rm -rf $(BUILD_DIST)/libgcrypt
	mkdir -p $(BUILD_DIST)/libgcrypt
	
	# libgcrypt.mk Prep libgcrypt
	cp -a $(BUILD_STAGE)/libgcrypt/usr $(BUILD_DIST)/libgcrypt
	
	# libgcrypt.mk Sign
	$(call SIGN,libgcrypt,general.xml)
	
	# libgcrypt.mk Make .debs
	$(call PACK,libgcrypt,DEB_LIBGCRYPT_V)
	
	# libgcrypt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgcrypt

.PHONY: libgcrypt libgcrypt-package
