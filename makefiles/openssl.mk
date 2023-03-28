ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && echo 1),1)
OPENSSL_VERSION := $(OPENSSL_CF1400_VERSION)
diskdev-cmds-setup: openssl_CF1400-setup
diskdev-cmds: openssl_CF1400
diskdev-cmds-package: openssl_CF1400-package

else
OPENSSL_VERSION := $(OPENSSL_CFBASE_VERSION)
openssl-setup: openssl_CFbase-setup
openssl: openssl_CFbase
openssl-package: openssl_CFbase-package

endif

STRAPPROJECTS   += openssl
