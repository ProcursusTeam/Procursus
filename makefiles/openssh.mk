ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssh
else # ($(SSH_STRAP),1)
SUBPROJECTS     += openssh
endif # ($(SSH_STRAP),1)
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS     += openssh
endif

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1700 ] && echo 1),1)
OPENSSH_VERSION := $(OPENSSH_CF1700_VERSION)
openssh-setup: openssh_CF1700-setup
openssh: openssh_CF1700
openssh-package: openssh_CF1700-package

else ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 600 ] && echo 1),1)
OPENSSH_VERSION := $(OPENSSH_CF600_VERSION)
openssh-setup: openssh_CF600-setup
openssh: openssh_CF600
openssh-package: openssh_CF600-package

else
OPENSSH_VERSION := $(OPENSSH_CFBASE_VERSION)
openssh-setup: openssh_CFbase-setup
openssh: openssh_CFbase
openssh-package: openssh_CFbase-package

endif