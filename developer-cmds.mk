ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS            += developer-cmds
DEVELOPER-CMDS_VERSION := 66
DEB_DEVELOPER-CMDS_V   ?= $(DEVELOPER-CMDS_VERSION)

developer-cmds-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/developer_cmds/developer_cmds-$(DEVELOPER-CMDS_VERSION).tar.gz
	$(call EXTRACT_TAR,developer_cmds-$(DEVELOPER-CMDS_VERSION).tar.gz,developer_cmds-$(DEVELOPER-CMDS_VERSION),developer-cmds)
	mkdir -p $(BUILD_STAGE)/developer-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_WORK)/developer-cmds/include
	cp -a $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{unistd,stdlib}.h $(BUILD_WORK)/developer-cmds/include

ifneq ($(wildcard $(BUILD_WORK)/developer-cmds/.build_complete),)
developer-cmds:
	@echo "Using previously built developer-cmds."
else
developer-cmds: developer-cmds-setup
	cd $(BUILD_WORK)/developer-cmds; \
	for bin in ctags rpcgen unifdef; do \
		$(CC) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) $(PLATFORM_VERSION_MIN) -isystem include -DPLATFORM_iPhoneOS -o $(BUILD_STAGE)/developer-cmds/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin/*.c -D_POSIX_C_SOURCE=200112L -DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR; \
	done
	touch $(BUILD_WORK)/developer-cmds/.build_complete
endif

developer-cmds-package: developer-cmds-stage
	# developer-cmds.mk Package Structure
	rm -rf $(BUILD_DIST)/developer-cmds

	# developer-cmds.mk Prep developer-cmds
	cp -a $(BUILD_STAGE)/developer-cmds $(BUILD_DIST)

	# developer-cmds.mk Sign
	$(call SIGN,developer-cmds,general.xml)

	# developer-cmds.mk Make .debs
	$(call PACK,developer-cmds,DEB_DEVELOPER-CMDS_V)

	# developer-cmds.mk Build cleanup
	rm -rf $(BUILD_DIST)/developer-cmds

.PHONY: developer-cmds developer-cmds-package

endif # ($(MEMO_TARGET),darwin-\*)