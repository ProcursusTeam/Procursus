ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS       += appuninst
APPUNINST_VERSION := 1.0.0
DEB_APPUNINST_V   ?= $(APPUNINST_VERSION)
APPUNINST_LIBS		:= -framework Foundation -framework CoreServices

appuninst-setup: setup
	$(call GITHUB_ARCHIVE,quiprr,appuninst,$(APPUNINST_VERSION),v$(APPUNINST_VERSION))
	$(call EXTRACT_TAR,appuninst-$(APPUNINST_VERSION).tar.gz,appuninst-$(APPUNINST_VERSION),appuninst)
	mkdir -p $(BUILD_STAGE)/appuninst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/appuninst/.build_complete),)
appuninst:
	@echo "Using previously built appuninst."
else
appuninst: appuninst-setup
	$(CC) $(CFLAGS) -fobjc-arc \
		$(BUILD_WORK)/appuninst/Sources/appuninst.m \
		-o $(BUILD_STAGE)/appuninst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/appuninst \
		$(LDFLAGS) \
		$(APPUNINST_LIBS)

	touch $(BUILD_WORK)/appuninst/.build_complete
endif

appuninst-package: appuninst-stage
	# appuninst.mk Package Structure
	rm -rf $(BUILD_DIST)/appuninst
	mkdir -p $(BUILD_DIST)/appuninst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# appuninst.mk Prep appuninst
	cp -a $(BUILD_STAGE)/appuninst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/appuninst $(BUILD_DIST)/appuninst/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# appuninst.mk Sign
	$(call SIGN,appuninst,appuninst.plist)

	# appuninst.mk Make .debs
	$(call PACK,appuninst,DEB_APPUNINST_V)

	# appuninst.mk Build cleanup
	rm -rf $(BUILD_DIST)/appuninst

.PHONY: appuninst appuninst-package

endif # ($(MEMO_TARGET),darwin-\*)
