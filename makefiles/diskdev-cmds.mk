ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1900 ] && echo 1),1)
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CF1900_VERSION)
diskdev-cmds-setup: diskdev-cmds_CF1900-setup
diskdev-cmds: diskdev-cmds_CF1900
diskdev-cmds-package: diskdev-cmds_CF1900-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1800 ] && echo 1),1)
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CF1800_VERSION)
diskdev-cmds-setup: diskdev-cmds_CF1800-setup
diskdev-cmds: diskdev-cmds_CF1800
diskdev-cmds-package: diskdev-cmds_CF1800-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CF1600_VERSION)
diskdev-cmds-setup: diskdev-cmds_CF1600-setup
diskdev-cmds: diskdev-cmds_CF1600
diskdev-cmds-package: diskdev-cmds_CF1600-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 800 ] && echo 1),1)
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CF800_VERSION)
diskdev-cmds-setup: diskdev-cmds_CF800-setup
diskdev-cmds: diskdev-cmds_CF800
diskdev-cmds-package: diskdev-cmds_CF800-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 700 ] && echo 1),1)
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CF700_VERSION)
diskdev-cmds-setup: diskdev-cmds_CF700-setup
diskdev-cmds: diskdev-cmds_CF700
diskdev-cmds-package: diskdev-cmds_CF700-package

else
DISKDEV-CMDS_VERSION := $(DISKDEV-CMDS_CFBASE_VERSION)
diskdev-cmds-setup: diskdev-cmds_CFbase-setup
diskdev-cmds: diskdev-cmds_CFbase
diskdev-cmds-package: diskdev-cmds_CFbase-package

endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS        += diskdev-cmds
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS          += diskdev-cmds
endif # ($(MEMO_TARGET),darwin-\*)
