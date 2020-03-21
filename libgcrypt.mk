ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBGCRYPT_VERSION := 1.8.5
DEB_LIBGCRYPT_V   ?= $(LIBGCRYPT_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/libgcrypt/.build_complete),)
libgcrypt:
	@echo "Using previously built libgcrypt."
else
libgcrypt: setup libgpg-error
	cd $(BUILD_WORK)/libgcrypt && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	@# TODO: Need to clean this up but don't want to use a patch...
	$(SED) -i '/.type  _gcry_mpih_add_n/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-add1.S
	$(SED) -i '/.size _gcry_mpih_add_n/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-add1.S
	$(SED) -i '/.type  _gcry_mpih_sub_n/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-sub1.S
	$(SED) -i '/.size _gcry_mpih_sub_n/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-sub1.S
	$(SED) -i '/.type  _gcry_mpih_mul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul1.S
	$(SED) -i '/.size _gcry_mpih_mul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul1.S
	$(SED) -i '/.type  _gcry_mpih_addmul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul2.S
	$(SED) -i '/.size _gcry_mpih_addmul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul2.S
	$(SED) -i '/.type  _gcry_mpih_submul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul3.S
	$(SED) -i '/.size _gcry_mpih_submul_1/d' $(BUILD_WORK)/libgcrypt/mpi/aarch64/mpih-mul3.S
	$(MAKE) -C $(BUILD_WORK)/libgcrypt
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgcrypt install \
		DESTDIR=$(BUILD_STAGE)/libgcrypt
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgcrypt install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgcrypt/.build_complete
endif

.PHONY: libgcrypt
