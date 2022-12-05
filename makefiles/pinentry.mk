ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pinentry
PINENTRY_VERSION := 1.2.0
DEB_PINENTRY_V   ?= $(PINENTRY_VERSION)

pinentry-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://gnupg.org/ftp/gcrypt/pinentry/pinentry-$(PINENTRY_VERSION).tar.bz2{$(comma).sig})
	$(call PGP_VERIFY,pinentry-$(PINENTRY_VERSION).tar.bz2)
	$(call EXTRACT_TAR,pinentry-$(PINENTRY_VERSION).tar.bz2,pinentry-$(PINENTRY_VERSION),pinentry)

ifneq ($(wildcard $(BUILD_WORK)/pinentry/.build_complete),)
pinentry:
	@echo "Using previously built pinentry."
else
pinentry: pinentry-setup libgpg-error libassuan ncurses
	cd $(BUILD_WORK)/pinentry && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libassuan-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-libgpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--enable-pinentry-tty \
		--enable-pinentry-ncurses \
		NCURSES_CFLAGS="-DNCURSES_WIDECHAR"
	+$(MAKE) -C $(BUILD_WORK)/pinentry
	+$(MAKE) -C $(BUILD_WORK)/pinentry install \
		DESTDIR="$(BUILD_STAGE)/pinentry"
	$(call AFTER_BUILD)
endif

pinentry-package: pinentry-stage
	# pinentry.mk Package Structure
	rm -rf $(BUILD_DIST)/pinentry

	# pinentry.mk Prep pinentry
	cp -a $(BUILD_STAGE)/pinentry $(BUILD_DIST)/

	# pinentry.mk Sign
	$(call SIGN,pinentry,general.xml)

	# pinentry.mk Make .debs
	$(call PACK,pinentry,DEB_PINENTRY_V)

	# pinentry.mk Build cleanup
	rm -rf $(BUILD_DIST)/pinentry

.PHONY: pinentry pinentry-package

