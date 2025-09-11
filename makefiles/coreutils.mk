ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 3000 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF3000_VERSION)
coreutils-setup: coreutils_CF3000-setup
coreutils: coreutils_CF3000
coreutils-package: coreutils_CF3000-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF1900_VERSION)
coreutils-setup: coreutils_CF1900-setup
coreutils: coreutils_CF1900
coreutils-package: coreutils_CF1900-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF1600_VERSION)
coreutils-setup: coreutils_CF1600-setup
coreutils: coreutils_CF1600
coreutils-package: coreutils_CF1600-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1400 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF1400_VERSION)
coreutils-setup: coreutils_CF1400-setup
coreutils: coreutils_CF1400
coreutils-package: coreutils_CF1400-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1000 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF1000_VERSION)
coreutils-setup: coreutils_CF1000-setup
coreutils: coreutils_CF1000
coreutils-package: coreutils_CF1000-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF800_VERSION)
coreutils-setup: coreutils_CF800-setup
coreutils: coreutils_CF800
coreutils-package: coreutils_CF800-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 600 ] && echo 1),1)
COREUTILS_VERSION := $(COREUTILS_CF600_VERSION)
coreutils-setup: coreutils_CF600-setup
coreutils: coreutils_CF600
coreutils-package: coreutils_CF600-package

else
COREUTILS_VERSION := $(COREUTILS_CFBASE_VERSION)
coreutils-setup: coreutils_CFbase-setup
coreutils: coreutils_CFbase
coreutils-package: coreutils_CFbase-package

endif

STRAPPROJECTS     += coreutils