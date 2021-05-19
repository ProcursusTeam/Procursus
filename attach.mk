ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS    += attach
ATTACH_COMMIT  := d07a4867400284633cc9fe643751059afc96de4a
ATTACH_VERSION := 0.0.3
DEB_ATTACH_V   ?= $(ATTACH_VERSION)

attach-setup: setup
	$(call GITHUB_ARCHIVE,NyaMisty,Attach-Detach,$(ATTACH_COMMIT),$(ATTACH_COMMIT),attach)
	$(call EXTRACT_TAR,attach-$(ATTACH_COMMIT).tar.gz,attach-detach-$(ATTACH_COMMIT),attach)
	mkdir -p $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	wget -q -nc -P $(BUILD_WORK)/attach \
		https://raw.githubusercontent.com/elihwyma/iOS-SDK-With-Passion/uwu/iPhoneOS14.0.sdk/System/Library/PrivateFrameworks/DiskImages2.framework/DiskImages2.tbd

ifneq ($(wildcard $(BUILD_WORK)/attach/.build_complete),)
attach:
	@echo "Using previously built attach."
else
attach: attach-setup
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/attach2 $(BUILD_WORK)/attach/attach2.m $(LDFLAGS) -framework Foundation -framework IOKit $(BUILD_WORK)/attach/DiskImages2.tbd
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/attach $(BUILD_WORK)/attach/attach.m $(LDFLAGS) -framework CoreFoundation -framework IOKit
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/detach $(BUILD_WORK)/attach/detach.c $(LDFLAGS) -framework CoreFoundation -framework IOKit
	touch $(BUILD_WORK)/attach/.build_complete
endif

attach-package: attach-stage
	# attach.mk Package Structure
	rm -rf $(BUILD_DIST)/attach

	# attach.mk Prep attach
	cp -a $(BUILD_STAGE)/attach $(BUILD_DIST)

	# attach.mk Sign
	$(call SIGN,attach,attach.xml)

	# attach.mk Make .debs
	$(call PACK,attach,DEB_ATTACH_V)

	# attach.mk Build cleanup
	rm -rf $(BUILD_DIST)/attach

.PHONY: attach attach-package

endif