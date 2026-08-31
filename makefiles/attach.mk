ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS    += attach
ATTACH_COMMIT  := d07a4867400284633cc9fe643751059afc96de4a
ATTACH_VERSION := 0.0.2+git20210424.$(shell echo $(ATTACH_COMMIT) | cut -c -7)
DEB_ATTACH_V   ?= $(ATTACH_VERSION)

attach-setup: setup
	$(call GITHUB_ARCHIVE,NyaMisty,Attach-Detach,$(ATTACH_COMMIT),$(ATTACH_COMMIT),attach)
	$(call EXTRACT_TAR,attach-$(ATTACH_COMMIT).tar.gz,attach-detach-$(ATTACH_COMMIT),attach)
	mkdir -p $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/attach/.build_complete),)
attach:
	@echo "Using previously built attach."
else
attach: attach-setup
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/attach2 $(BUILD_WORK)/attach/attach2.m $(LDFLAGS) -framework Foundation -framework IOKit -F$(BUILD_MISC)/PrivateFrameworks -framework DiskImages2
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/attach $(BUILD_WORK)/attach/attach.m $(LDFLAGS) -framework CoreFoundation -framework IOKit
	$(CC) $(CFLAGS) -o $(BUILD_STAGE)/attach/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/detach $(BUILD_WORK)/attach/detach.c $(LDFLAGS) -framework CoreFoundation -framework IOKit
	$(call AFTER_BUILD)
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
