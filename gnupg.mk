ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

GNUPG_VERSION := 2.2.19
DEB_GNUPG_V   ?= $(GNUPG_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/gnupg/.build_complete),)
gnupg:
	@echo "Using previously built libassuan."
else
gnupg: setup readline libgpg-error libgcrypt libassuan libksba npth
	cd $(BUILD_WORK)/gnupg && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr \
		--with-libassuan-prefix=$(BUILD_BASE)/usr \
		--with-npth-prefix=$(BUILD_BASE)/usr \
		--with-libgcrypt-prefix=$(BUILD_BASE)/usr \
		--with-ksba-prefix=$(BUILD_BASE)/usr \
		--with-bzip2
	$(MAKE) -C $(BUILD_WORK)/gnupg
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_STAGE)/gnupg
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gnupg/.build_complete
endif

.PHONY: gnupg
