ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1800 ] && echo 1),1)
SYSTEM-CMDS_VERSION := $(SYSTEM-CMDS_CF1800_VERSION)
system-cmds-setup: system-cmds_CF1800-setup
system-cmds: system-cmds_CF1800
system-cmds-package: system-cmds_CF1800-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && echo 1),1)
SYSTEM-CMDS_VERSION := $(SYSTEM-CMDS_CF1700_VERSION)
system-cmds-setup: system-cmds_CF1700-setup
system-cmds: system-cmds_CF1700
system-cmds-package: system-cmds_CF1700-package

else
SYSTEM-CMDS_VERSION := $(SYSTEM-CMDS_CFbase_VERSION)
system-cmds-setup: system-cmds_CFbase-setup
system-cmds: system-cmds_CFbase
system-cmds-package: system-cmds_CFbase-package

endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS        += system-cmds
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS          += system-cmds
endif # ($(MEMO_TARGET),darwin-\*)
