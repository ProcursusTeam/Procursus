ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && echo 1),1)
setup: setup_CF1900

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && echo 1),1)
setup: setup_CF800

else
setup: setup_CFbase

endif