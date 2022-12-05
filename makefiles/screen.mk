ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += screen
SCREEN_VERSION := 4.9.0
DEB_SCREEN_V   ?= $(SCREEN_VERSION)

screen-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftp.gnu.org/gnu/screen/screen-$(SCREEN_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,screen-$(SCREEN_VERSION).tar.gz)
	$(call EXTRACT_TAR,screen-$(SCREEN_VERSION).tar.gz,screen-$(SCREEN_VERSION),screen)
	$(call DO_PATCH,screen,screen,-p1)

ifneq ($(wildcard $(BUILD_WORK)/screen/.build_complete),)
screen:
	@echo "Using previously built screen."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
screen: screen-setup ncurses libxcrypt
else
screen: screen-setup ncurses
endif
	cd $(BUILD_WORK)/screen && ./autogen.sh
	cd $(BUILD_WORK)/screen && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-colors256 \
		--disable-pam \
		--with-sys-screenrc=$(MEMO_PREFIX)/etc/screenrc
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i '/HAVE_EXECVPE/ s/$$/\n#define HAVE_EXECVPE 1/' $(BUILD_WORK)/screen/config.h
endif
	+$(MAKE) -C $(BUILD_WORK)/screen install \
		DESTDIR="$(BUILD_STAGE)/screen"
	rm -f $(BUILD_STAGE)/screen/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/screen && mv $(BUILD_STAGE)/screen/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/screen{-$(SCREEN_VERSION),}
	mkdir -p $(BUILD_STAGE)/screen/etc
	cp -a $(BUILD_WORK)/screen/etc/etcscreenrc $(BUILD_STAGE)/screen/etc/screenrc
	$(call AFTER_BUILD)
endif

screen-package: screen-stage
	# screen.mk Package Structure
	rm -rf $(BUILD_DIST)/screen

	# screen.mk Prep screen
	cp -a $(BUILD_STAGE)/screen $(BUILD_DIST)

	# screen.mk Sign
	$(call SIGN,screen,general.xml)

	# screen.mk Make .debs
	$(call PACK,screen,DEB_SCREEN_V)

	# screen.mk Build cleanup
	rm -rf $(BUILD_DIST)/screen

.PHONY: screen screen-package
