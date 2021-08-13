ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(shell [ $(MEMO_CFVER) -ge 1700 ] && echo 1),1)

SUBPROJECTS         += bindfsprogs
BINDFSPROGS_VERSION := 0.1.4
DEB_BINDFSPROGS_V   ?= $(BINDFSPROGS_VERSION)

bindfsprogs-setup: setup
	$(call GITHUB_ARCHIVE,Halo-Michael,bindfs,$(BINDFSPROGS_VERSION),$(BINDFSPROGS_VERSION))
	$(call EXTRACT_TAR,bindfs-$(BINDFSPROGS_VERSION).tar.gz,bindfs-$(BINDFSPROGS_VERSION),bindfsprogs)
	mkdir -p $(BUILD_STAGE)/bindfsprogs/$(MEMO_PREFIX)/sbin

ifneq ($(wildcard $(BUILD_WORK)/bindfsprogs/.build_complete),)
bindfsprogs:
	@echo "Using previously built bindfsprogs."
else
bindfsprogs: bindfsprogs-setup
	cd $(BUILD_WORK)/bindfsprogs && \
	$(CC) $(CFLAGS) -lutil mount_bindfs.c -o $(BUILD_STAGE)/bindfsprogs/$(MEMO_PREFIX)/sbin/mount_bindfs
	$(call AFTER_BUILD)
endif

bindfsprogs-package: bindfsprogs-stage
	# bindfsprogs.mk Package Structure
	rm -rf $(BUILD_DIST)/bindfsprogs
	
	# bindfsprogs.mk Prep bindfsprogs
	cp -a $(BUILD_STAGE)/bindfsprogs $(BUILD_DIST)
	
	# bindfsprogs.mk Sign
	$(call SIGN,bindfsprogs,bindfs.xml)
	
	# bindfsprogs.mk Make .debs
	$(call PACK,bindfsprogs,DEB_BINDFSPROGS_V)
	
	# bindfsprogs.mk Build cleanup
	rm -rf $(BUILD_DIST)/bindfsprogs

.PHONY: bindfsprogs bindfsprogs-package

endif # ifeq ($(shell [ $(MEMO_CFVER) -ge 1700 ] && echo 1),1)

