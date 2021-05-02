ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += weechat
WEECHAT_VERSION := 2.9
DEB_WEECHAT_V   ?= $(WEECHAT_VERSION)

weechat-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.weechat.org/files/src/weechat-$(WEECHAT_VERSION).tar.xz
	$(call EXTRACT_TAR,weechat-$(WEECHAT_VERSION).tar.xz,weechat-$(WEECHAT_VERSION),weechat)

ifneq ($(wildcard $(BUILD_WORK)/weechat/.build_complete),)
weechat:
	@echo "Using previously built weechat."
else
weechat: weechat-setup ncurses gettext gnutls curl libgcrypt
	cd $(BUILD_WORK)/weechat && ./autogen.sh
	cd $(BUILD_WORK)/weechat && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--disable-static \
		--disable-alias \
		--disable-buflist \
		--disable-charset \
		--disable-exec \
		--disable-fifo \
		--disable-fset \
		--disable-ruby \
		--disable-lua \
		--disable-tcl \
		--disable-guile \
		--disable-javascript \
		--disable-php \
		--disable-spell \
		--disable-enchant \
		--disable-perl \
		--disable-python
	+$(MAKE) -C $(BUILD_WORK)/weechat
	+$(MAKE) -C $(BUILD_WORK)/weechat install \
		DESTDIR=$(BUILD_STAGE)/weechat
	touch $(BUILD_WORK)/weechat/.build_complete
endif

weechat-package: weechat-stage
	# weechat.mk Package Structure
	rm -rf $(BUILD_DIST)/weechat{,-core,-curses,-headless,-dev}
	mkdir -p $(BUILD_DIST)/weechat{,-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/weechat} \
	$(BUILD_DIST)/weechat-curses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	$(BUILD_DIST)/weechat-headless/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
	$(BUILD_DIST)/weechat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# weechat.mk Prep weechat-core
	cp -a $(BUILD_STAGE)/weechat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/weechat $(BUILD_DIST)/weechat-core/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# weechat.mk Prep weechat-curses
	cp -a $(BUILD_STAGE)/weechat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/weechat{,-curses} $(BUILD_DIST)/weechat-curses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# weechat.mk Prep weechat-headless
	cp -a $(BUILD_STAGE)/weechat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/weechat-headless $(BUILD_DIST)/weechat-headless/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# weechat.mk Prep weechat-dev
	cp -a $(BUILD_STAGE)/weechat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/weechat-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# weechat.mk Sign
	$(call SIGN,weechat-core,general.xml)
	$(call SIGN,weechat-curses,general.xml)
	$(call SIGN,weechat-headless,general.xml)

	# weechat.mk Make .debs
	$(call PACK,weechat,DEB_WEECHAT_V)
	$(call PACK,weechat-core,DEB_WEECHAT_V)
	$(call PACK,weechat-curses,DEB_WEECHAT_V)
	$(call PACK,weechat-headless,DEB_WEECHAT_V)
	$(call PACK,weechat-dev,DEB_WEECHAT_V)

	# weechat.mk Build cleanup
	rm -rf $(BUILD_DIST)/weechat{,-core,-curses,-headless,-dev}

.PHONY: weechat weechat-package
