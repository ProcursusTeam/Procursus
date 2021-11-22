ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pinentry
PINENTRY_VERSION := 1.1.1.1
DEB_PINENTRY_V   ?= $(PINENTRY_VERSION)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
PINENTRY_SED_COMMAND := sed -i 's|pinentry_macosx=no|pinentry_macosx=yes|g' $(BUILD_WORK)/pinentry/configure
else
PINENTRY_SED_COMMAND := true
endif

pinentry-setup: setup
	$(call GITHUB_ARCHIVE,GPGTools,pinentry,$(PINENTRY_VERSION),v$(PINENTRY_VERSION))
	$(call EXTRACT_TAR,pinentry-$(PINENTRY_VERSION).tar.gz,pinentry-$(PINENTRY_VERSION),pinentry)

ifneq ($(wildcard $(BUILD_WORK)/pinentry/.build_complete),)
pinentry:
	@echo "Using previously built pinentry."
else
pinentry: pinentry-setup libgpg-error libassuan ncurses
	touch $(BUILD_WORK)/pinentry/doc/version.texi
	cd $(BUILD_WORK)/pinentry && autoreconf -fi && $(PINENTRY_SED_COMMAND) && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-pinentry-tty \
		--enable-pinentry-ncurses \
		NCURSES_CFLAGS="-DNCURSES_WIDECHAR"
	+$(MAKE) -C $(BUILD_WORK)/pinentry
	+$(MAKE) -C $(BUILD_WORK)/pinentry install \
		DESTDIR="$(BUILD_STAGE)/pinentry"
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Applications
	cp -r $(BUILD_WORK)/pinentry/macosx/pinentry-mac.app $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Applications/pinentry-mac.app
endif
	$(call AFTER_BUILD)
endif

pinentry-package: pinentry-stage
	# pinentry.mk Package Structure
	rm -rf $(BUILD_DIST)/pinentry
	mkdir -p $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pinentry.mk Prep pinentry
	cp -a $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Applications $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(INSTALL) -Dm755 $(BUILD_MISC)/pinentry-macosx $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pinentry-macosx
	sed -i 's|@PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Applications/pinentry-mac.app/Contents/MacOS|g' \
			$(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pinentry-macosx
endif

	# pinentry.mk Sign
	$(call SIGN,pinentry,general.xml)

	# pinentry.mk Make .debs
	$(call PACK,pinentry,DEB_PINENTRY_V)

	# pinentry.mk Build cleanup
	rm -rf $(BUILD_DIST)/pinentry

.PHONY: pinentry pinentry-package

