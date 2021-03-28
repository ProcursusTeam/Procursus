ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS          += bsdgames
BSDGAMES_VERSION       := 9.99.80
BSDGAMES-DARWIN_COMMIT := 23454acb66be2a88647262d98d50e0f115519ea0
DEB_BSDGAMES_V         ?= $(BSDGAMES_VERSION)

bsdgames-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/bsdgames-darwin-$(BSDGAMES-DARWIN_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/bsdgames-darwin-$(BSDGAMES-DARWIN_COMMIT).tar.gz \
			https://github.com/CRKatri/bsdgames-darwin/archive/$(BSDGAMES-DARWIN_COMMIT).tar.gz
	$(call EXTRACT_TAR,bsdgames-darwin-$(BSDGAMES-DARWIN_COMMIT).tar.gz,bsdgames-darwin-$(BSDGAMES-DARWIN_COMMIT),bsdgames)

ifneq ($(wildcard $(BUILD_WORK)/bsdgames/.build_complete),)
bsdgames:
	@echo "Using previously built bsdgames."
else
bsdgames: bsdgames-setup ncurses flex openssl
	+$(MAKE) -C $(BUILD_WORK)/bsdgames \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		LOCALSTATEDIR="$(MEMO_PREFIX)/var" \
		SYSCONFDIR="$(MEMO_PREFIX)/etc" \
		LIBFLA="$(BUILD_BASE)/usr/lib/libfl.2.dylib"
	+$(MAKE) -C $(BUILD_WORK)/bsdgames install \
		DESTDIR="$(BUILD_STAGE)/bsdgames" \
		GINSTALL="$(GINSTALL)" \
		LN="$(LN)"
	touch $(BUILD_WORK)/bsdgames/.build_complete
endif

bsdgames-package: bsdgames-stage
	# bsdgames.mk Package Structure
	rm -rf $(BUILD_DIST)/bsdgames
	
	# bsdgames.mk Prep bsdgames
	cp -a $(BUILD_STAGE)/bsdgames $(BUILD_DIST)
	
	# bsdgames.mk Sign
	$(call SIGN,bsdgames,general.xml)
	
	# bsdgames.mk Make .debs
	$(call PACK,bsdgames,DEB_BSDGAMES_V)
	
	# bsdgames.mk Build cleanup
	rm -rf $(BUILD_DIST)/bsdgames

.PHONY: bsdgames bsdgames-package
