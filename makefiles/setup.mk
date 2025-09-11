ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 3000 ] && echo 1),1)
setup: setup_CF3000

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && echo 1),1)
setup: setup_CF2000

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && echo 1),1)
setup: setup_CF1900

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1100 ] && echo 1),1)
setup: setup_CF1100

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1000 ] && echo 1),1)
setup: setup_CF1000

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 700 ] && echo 1),1)
setup: setup_CF700

else
setup: setup_CFbase

endif