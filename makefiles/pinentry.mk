ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pinentry
PINENTRY_VERSION := 1.1.1
DEB_PINENTRY_V   ?= $(PINENTRY_VERSION)

pinentry-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-$(PINENTRY_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,pinentry-$(PINENTRY_VERSION).tar.bz2)
	$(call EXTRACT_TAR,pinentry-$(PINENTRY_VERSION).tar.bz2,pinentry-$(PINENTRY_VERSION),pinentry)

ifneq ($(wildcard $(BUILD_WORK)/pinentry/.build_complete),)
pinentry:
	@echo "Using previously built libassuan."
else
pinentry: pinentry-setup libgpg-error libassuan ncurses
	cd $(BUILD_WORK)/pinentry && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-pinentry-fltk \
		--disable-pinentry-gnome3 \
		--disable-pinentry-gtk2 \
		--disable-pinentry-qt \
		--disable-pinentry-qt5 \
		--disable-pinentry-tqt \
		--enable-pinentry-tty \
		NCURSES_CFLAGS="-DNCURSES_WIDECHAR"
	+$(MAKE) -C $(BUILD_WORK)/pinentry
	+$(MAKE) -C $(BUILD_WORK)/pinentry install \
		DESTDIR="$(BUILD_STAGE)/pinentry"
	touch $(BUILD_WORK)/pinentry/.build_complete
endif

pinentry-package: pinentry-stage
	# pinentry.mk Package Structure
	rm -rf $(BUILD_DIST)/pinentry
	mkdir -p $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pinentry.mk Prep pinentry
	cp -a $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pinentry.mk Sign
	$(call SIGN,pinentry,general.xml)

	# pinentry.mk Make .debs
	$(call PACK,pinentry,DEB_PINENTRY_V)

	# pinentry.mk Build cleanup
	rm -rf $(BUILD_DIST)/pinentry

.PHONY: pinentry pinentry-package

