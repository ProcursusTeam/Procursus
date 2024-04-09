ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
SUBPROJECTS        += uikittools
else
STRAPPROJECTS      += uikittools
endif
UIKITTOOLS_VERSION := 2.1.6
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)-1

ifeq ($(PLATFORM),iphoneos)
TBD_PLATFORM = ios
else ifeq ($(PLATFORM),macosx)
TBD_PLATFORM = macos
else ifeq ($(PLATFORM),appletvos)
TBD_PLATFORM = tvos
else
TBD_PLATFORM = $(PLATFORM)
endif

uikittools-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,uikittools-ng,$(UIKITTOOLS_VERSION),v$(UIKITTOOLS_VERSION))
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz,uikittools-ng-$(UIKITTOOLS_VERSION),uikittools)
	sed -i 's/(null)/$(TBD_PLATFORM)/g' $(BUILD_WORK)/uikittools/Frameworks/MobileContainerManager.framework/MobileContainerManager.tbd

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
UIKITTOOLS_MAKE_ARGS += NO_COMPAT=1
endif

ifneq ($(wildcard $(BUILD_WORK)/uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: uikittools-setup gettext
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		LOCALEDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale" \
		APP_PATH="$(MEMO_PREFIX)/Applications" \
		NLS=1
	+$(MAKE) -C $(BUILD_WORK)/uikittools install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		LOCALEDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale" \
		DESTDIR="$(BUILD_STAGE)/uikittools" \
		APP_PATH="$(MEMO_PREFIX)/Applications" \
		NLS=1 \
		$(UIKITTOOLS_MAKE_ARGS)
	$(call AFTER_BUILD)
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools{,-extra}

	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)
	rm -f $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{uinotify,uisave,lsrebuild,uidisplay,uishoot} \
		$(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{uinotify,uisave,lsrebuild,uidisplay,uishoot}.1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*/man1/{uinotify,uisave,lsrebuild,uidisplay,uishoot}.1$(MEMO_MANPAGE_SUFFIX)

ifeq (,$(findstring bridgeos,$(MEMO_TARGET)))
	# uikittools.mk Prep uikittools-extra
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)/uikittools-extra
	rm -rf $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(uinotify|uisave|lsrebuild|uidisplay|uishoot) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/!(uinotify|uisave|lsrebuild|uidisplay|uishoot).1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*/man1/!(uinotify|uisave|lsrebuild|uidisplay|uishoot).1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale
endif

	# uikittools.mk Sign
	$(call SIGN,uikittools,general.xml)
ifeq (,$(findstring bridgeos,$(MEMO_TARGET)))
	$(call SIGN,uikittools-extra,general.xml)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq (,$(findstring bridgeos,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_WORK)/uikittools/lsrebuild.plist $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsrebuild
	$(LDID) -S$(BUILD_MISC)/entitlements/sbreload.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sbreload
	$(LDID) -S$(BUILD_WORK)/uikittools/uialert.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uialert
	$(LDID) -S$(BUILD_WORK)/uikittools/uicache.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uicache
	$(LDID) -S$(BUILD_WORK)/uikittools/uiopen.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uiopen
	$(LDID) -S$(BUILD_WORK)/uikittools/uishoot.plist $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uishoot
endif
	$(LDID) -S$(BUILD_WORK)/uikittools/mgask.plist $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mgask
ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_WORK)/uikittools/uidisplay.plist $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uidisplay
	$(LDID) -S$(BUILD_WORK)/uikittools/uinotify.plist $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uinotify
	$(LDID) -S$(BUILD_WORK)/uikittools/uisave.plist $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/uisave
endif
ifeq (,$(findstring bridgeos,$(MEMO_TARGET)))
	find $(BUILD_DIST)/uikittools-extra -name '.ldid*' -type f -delete
endif
	find $(BUILD_DIST)/uikittools -name '.ldid*' -type f -delete
endif

	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)
ifeq (,$(findstring bridgeos,$(MEMO_TARGET)))
	$(call PACK,uikittools-extra,DEB_UIKITTOOLS_V)
endif

	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools{,-extra}

.PHONY: uikittools uikittools-package
