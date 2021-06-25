ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS            += bootstrap-cmds
BOOTSTRAP-CMDS_VERSION := 121
DEB_BOOTSTRAP-CMDS_V   ?= $(BOOTSTRAP-CMDS_VERSION)

bootstrap-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/bootstrap_cmds/bootstrap_cmds-$(BOOTSTRAP-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,bootstrap_cmds-$(BOOTSTRAP-CMDS_VERSION).tar.gz,bootstrap_cmds-$(BOOTSTRAP-CMDS_VERSION),bootstrap-cmds)
	mkdir -p $(BUILD_STAGE)/bootstrap-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec}

ifneq ($(wildcard $(BUILD_WORK)/bootstrap-cmds/.build_complete),)
bootstrap-cmds:
	@echo "Using previously built bootstrap-cmds."
else
bootstrap-cmds: .SHELLFLAGS=-O extglob -c
bootstrap-cmds: bootstrap-cmds-setup
	cd $(BUILD_WORK)/bootstrap-cmds/migcom.tproj; \
	yacc -d parser.y; \
	lex lexxer.l; \
	$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -DMIG_VERSION=\"mig-$(BOOTSTRAP-CMDS_VERSION)\" -o migcom !(handler).c -save-temps; \
	cp -a migcom $(BUILD_STAGE)/bootstrap-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec; \
	cp -a mig.sh $(BUILD_STAGE)/bootstrap-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mig
	touch $(BUILD_WORK)/bootstrap-cmds/.build_complete
endif

bootstrap-cmds-package: bootstrap-cmds-stage
	# bootstrap-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/bootstrap-cmds

	# bootstrap-cmds.mk Prep bootstrap-cmds
	cp -a $(BUILD_STAGE)/bootstrap-cmds $(BUILD_DIST)

	# bootstrap-cmds.mk Sign
	$(call SIGN,bootstrap-cmds,general.xml)

	# bootstrap-cmds.mk Permissions
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/bootstrap-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mig

	# bootstrap-cmds.mk Make .debs
	$(call PACK,bootstrap-cmds,DEB_BOOTSTRAP-CMDS_V)

	# bootstrap-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/bootstrap-cmds

.PHONY: bootstrap-cmds bootstrap-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)