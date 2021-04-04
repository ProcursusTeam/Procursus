ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS                   += gettext-localizations
GETTEXT-LOCALIZATIONS_VERSION := 2020.10.07
DEB_GETTEXT-LOCALIZATIONS_V   ?= $(GETTEXT-LOCALIZATIONS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/gettext-localizations/.build_complete),)
gettext-localizations:
	@echo "Using previously built gettext-localizations."
else ifeq ($(shell [ $(UNAME) = Darwin ] && [ -f "/System/Library/Kernels/kernel" ] && echo 1),1)
gettext-localizations: setup
	mkdir -p $(BUILD_STAGE)/gettext-localizations/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -af /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_STAGE)/gettext-localizations/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -f $(BUILD_STAGE)/gettext-localizations/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale/locale.alias
else
gettext-localizations:
	@echo "Please make gettext-localizations from a Mac."
endif

gettext-localizations-package: gettext-localizations-stage
	# gettext-localizations.mk Package Structure
	rm -rf $(BUILD_DIST)/gettext-localizations

	# gettext-localizations.mk Prep gettext-localizations
	cp -a $(BUILD_STAGE)/gettext-localizations $(BUILD_DIST)

	# gettext-localizations.mk Make .debs
	$(call PACK,gettext-localizations,DEB_GETTEXT-LOCALIZATIONS_V)

	# gettext-localizations.mk Build cleanup
	rm -rf $(BUILD_DIST)/gettext-localizations

.PHONY: gettext-localizations gettext-localizations-package

endif