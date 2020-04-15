ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gnupg
DOWNLOAD      += https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(GNUPG_VERSION).tar.bz2{,.sig}
GNUPG_VERSION := 2.2.20
DEB_GNUPG_V   ?= $(GNUPG_VERSION)

gnupg-setup: setup
	$(call PGP_VERIFY,gnupg-$(GNUPG_VERSION).tar.bz2)
	$(call EXTRACT_TAR,gnupg-$(GNUPG_VERSION).tar.bz2,gnupg-$(GNUPG_VERSION),gnupg)

ifneq ($(wildcard $(BUILD_WORK)/gnupg/.build_complete),)
gnupg:
	@echo "Using previously built libassuan."
else
gnupg: gnupg-setup readline libgpg-error libgcrypt libassuan libksba npth
	cd $(BUILD_WORK)/gnupg && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr \
		--with-libassuan-prefix=$(BUILD_BASE)/usr \
		--with-npth-prefix=$(BUILD_BASE)/usr \
		--with-libgcrypt-prefix=$(BUILD_BASE)/usr \
		--with-ksba-prefix=$(BUILD_BASE)/usr \
		--with-bzip2 \
		--sysconfdir=/etc
	+$(MAKE) -C $(BUILD_WORK)/gnupg
	+$(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_STAGE)/gnupg
	+$(MAKE) -C $(BUILD_WORK)/gnupg install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gnupg/.build_complete
endif

gnupg-package: gnupg-stage
	# gnupg.mk Package Structure
	rm -rf $(BUILD_DIST)/gnupg
	mkdir -p $(BUILD_DIST)/gnupg
	
	# gnupg.mk Prep gnupg
	$(FAKEROOT) cp -a $(BUILD_STAGE)/gnupg/usr $(BUILD_DIST)/gnupg
	
	# gnupg.mk Sign
	$(call SIGN,gnupg,general.xml)
	
	# gnupg.mk Make .debs
	$(call PACK,gnupg,DEB_GNUPG_V)
	
	# gnupg.mk Build cleanup
	rm -rf $(BUILD_DIST)/gnupg

.PHONY: gnupg gnupg-package
