ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += gettext

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 3000 ] && echo 1),1)
GETTEXT_VERSION := $(GETTEXT_CF1500_VERSION)
gettext-setup: gettext_CF3000-setup
gettext: gettext_CF3000
gettext-package: gettext_CF3000-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1500 ] && echo 1),1)
GETTEXT_VERSION := $(GETTEXT_CF1500_VERSION)
gettext-setup: gettext_CF1500-setup
gettext: gettext_CF1500
gettext-package: gettext_CF1500-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1100 ] && echo 1),1)
GETTEXT_VERSION := $(GETTEXT_CF1100_VERSION)
gettext-setup: gettext_CF1100-setup
gettext: gettext_CF1100
gettext-package: gettext_CF1100-package

else
GETTEXT_VERSION := $(GETTEXT_CFBASE_VERSION)
gettext-setup: gettext_CFbase-setup
gettext: gettext_CFbase
gettext-package: gettext_CFbase-package

endif