ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF800_VERSION)
coreutils-setup: coreutils_CF800-setup
coreutils: coreutils_CF800
coreutils-package: coreutils_CF800-package

else
COREUTILS_VERSION := $(COREUTILS_CFBASE_VERSION)
coreutils-setup: coreutils_CFbase-setup
coreutils: coreutils_CFbase
coreutils-package: coreutils_CFbase-package

endif

STRAPPROJECTS     += coreutils