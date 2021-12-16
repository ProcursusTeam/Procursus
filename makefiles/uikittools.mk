ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring bridgeos,$(MEMO_TARGET)))
SUBPROJECTS        += uikittools
else
STRAPPROJECTS      += uikittools
endif
UIKITTOOLS_VERSION := 2.1.0
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

uikittools-setup: setup
	$(call GITHUB_ARCHIVE,ProcursusTeam,uikittools-ng,$(UIKITTOOLS_VERSION),v$(UIKITTOOLS_VERSION))
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz,uikittools-ng-$(UIKITTOOLS_VERSION),uikittools)

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
		NLS=1
	$(call AFTER_BUILD)
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools{,-extra}

	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)
	rm -f $(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{uinotify,uisave,lsrebuild,uidisplay,uialert,uishoot} \
		$(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{uinotify,uisave,lsrebuild,uidisplay,uialert,uishoot}.1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*/man1/{uinotify,uisave,lsrebuild,uidisplay,uialert,uishoot}.1$(MEMO_MANPAGE_SUFFIX)

	# uikittools.mk Prep uikittools-extra
	cp -a $(BUILD_STAGE)/uikittools $(BUILD_DIST)/uikittools-extra
	rm -rf $(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(uinotify|uisave|lsrebuild|uidisplay|uialert|uishoot) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/!(uinotify|uisave|lsrebuild|uidisplay|uialert|uishoot).1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/*/man1/!(uinotify|uisave|lsrebuild|uidisplay|uialert|uishoot).1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale

	# uikittools.mk Sign
	$(call SIGN,uikittools,general.xml)
	$(call SIGN,uikittools-extra,general.xml)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	for tool in $(BUILD_STAGE)/uikittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* \
		$(BUILD_STAGE)/uikittools-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		if [ -f $(BUILD_WORK)/uikittools/$$(basename $$tool).plist ]; then \
			$(LDID) -S$(BUILD_WORK)/uikittools/$$(basename $$tool).plist $$tool; \
		fi; \
	done
	find $(BUILD_DIST)/uikittools -name '.ldid*' -type f -delete
	find $(BUILD_DIST)/uikittools-extra -name '.ldid*' -type f -delete
endif

	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)
	$(call PACK,uikittools-extra,DEB_UIKITTOOLS_V)

	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools{,-extra}

.PHONY: uikittools uikittools-package
