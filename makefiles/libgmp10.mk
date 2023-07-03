ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 700 ] && echo 1),1)
LIBGMP10_VERSION := $(LIBGMP10_CF700_VERSION)
libgmp10-setup: libgmp10_CF700-setup
libgmp10: libgmp10_CF700
libgmp10-package: libgmp10_CF700-package

else
LIBGMP10_VERSION := $(LIBGMP10_CFBASE_VERSION)
libgmp10-setup: libgmp10_CFbase-setup
libgmp10: libgmp10_CFbase
libgmp10-package: libgmp10_CFbase-package

endif

STRAPPROJECTS     += libgmp10