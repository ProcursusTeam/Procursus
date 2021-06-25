ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                   += pasteboard-utils
PASTEBOARD-UTILS_VERSION      := 1.0.0
DEB_PASTEBOARD-UTILS_V        ?= $(PASTEBOARD-UTILS_VERSION)
PASTEBOARD-UTILS_LIBS         := -framework Foundation -framework UIKit

pasteboard-utils-setup: setup
	$(call GITHUB_ARCHIVE,quiprr,pasteboard-utils,$(PASTEBOARD-UTILS_VERSION),v$(PASTEBOARD-UTILS_VERSION))
	$(call EXTRACT_TAR,pasteboard-utils-$(PASTEBOARD-UTILS_VERSION).tar.gz,pasteboard-utils-$(PASTEBOARD-UTILS_VERSION),pasteboard-utils)
	mkdir -p $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/pasteboard-utils/.build_complete),)
pasteboard-utils:
	@echo "Using previously built pasteboard-utils."
else
pasteboard-utils: pasteboard-utils-setup
	$(CC) $(CFLAGS) -fobjc-arc \
		$(BUILD_WORK)/pasteboard-utils/pbupload/pbupload.m \
		-o $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbupload \
		$(LDFLAGS) \
		$(PASTEBOARD-UTILS_LIBS)

	$(CC) $(CFLAGS) -fobjc-arc \
		$(BUILD_WORK)/pasteboard-utils/pbcopy/pbcopy.m \
		-o $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbcopy \
		$(LDFLAGS) \
		$(PASTEBOARD-UTILS_LIBS)

	$(CC) $(CFLAGS) -fobjc-arc \
		$(BUILD_WORK)/pasteboard-utils/pbpaste/pbpaste.m \
		-o $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbpaste \
		$(LDFLAGS) \
		$(PASTEBOARD-UTILS_LIBS)

	touch $(BUILD_WORK)/pasteboard-utils/.build_complete
endif

pasteboard-utils-package: pasteboard-utils-stage
	# pasteboard-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/pasteboard-utils
	mkdir -p $(BUILD_DIST)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# pasteboard-utils.mk Prep pasteboard-utils
	cp -a $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbupload $(BUILD_DIST)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbcopy $(BUILD_DIST)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbpaste $(BUILD_DIST)/pasteboard-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# pasteboard-utils.mk Sign
	$(call SIGN,pasteboard-utils,general.xml)

	# pasteboard-utils.mk Make .debs
	$(call PACK,pasteboard-utils,DEB_PASTEBOARD-UTILS_V)

	# pasteboard-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/pasteboard-utils

.PHONY: pasteboard-utils pasteboard-utils-package
