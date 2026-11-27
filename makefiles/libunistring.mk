ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += libunistring

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 600 ] && echo 1),1)
UNISTRING_VERSION := $(UNISTRING_CF600_VERSION)
libunistring-setup: libunistring_CF600-setup
libunistring: libunistring_CF600
libunistring-package: libunistring_CF600-package

else
UNISTRING_VERSION := $(UNISTRING_CFBASE_VERSION)
libunistring-setup: libunistring_CFbase-setup
libunistring: libunistring_CFbase
libunistring-package: libunistring_CFbase-package

endif