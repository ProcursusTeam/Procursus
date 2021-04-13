ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                 += zsh-autosuggestions
ZSH-AUTOSUGGESTIONS_VERSION := 0.6.4
DEB_ZSH-AUTOSUGGESTIONS_V   ?= $(ZSH-AUTOSUGGESTIONS_VERSION)

zsh-autosuggestions-setup: setup
	$(call GITHUB_ARCHIVE,zsh-users,zsh-autosuggestions,$(ZSH-AUTOSUGGESTIONS_VERSION),v$(ZSH-AUTOSUGGESTIONS_VERSION))
	$(call EXTRACT_TAR,zsh-autosuggestions-$(ZSH-AUTOSUGGESTIONS_VERSION).tar.gz,zsh-autosuggestions-$(ZSH-AUTOSUGGESTIONS_VERSION),zsh-autosuggestions)

ifneq ($(wildcard $(BUILD_WORK)/zsh-autosuggestions/.build_complete),)
zsh-autosuggestions:
	@echo "Using previously built zsh-autosuggestions."
else
zsh-autosuggestions: zsh-autosuggestions-setup ncurses gettext file
	+$(MAKE) -C $(BUILD_WORK)/zsh-autosuggestions
	$(GINSTALL) -Dm644 $(BUILD_WORK)/zsh-autosuggestions/zsh-autosuggestions.zsh \
		$(BUILD_STAGE)/zsh-autosuggestions/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
	touch $(BUILD_WORK)/zsh-autosuggestions/.build_complete
endif

zsh-autosuggestions-package: zsh-autosuggestions-stage
	# zsh-autosuggestions.mk Package Structure
	rm -rf $(BUILD_DIST)/zsh-autosuggestions
	mkdir -p $(BUILD_DIST)/zsh-autosuggestions

	# zsh-autosuggestions.mk Prep zsh-autosuggestions
	cp -a $(BUILD_STAGE)/zsh-autosuggestions $(BUILD_DIST)

	# zsh-autosuggestions.mk Make .debs
	$(call PACK,zsh-autosuggestions,DEB_ZSH-AUTOSUGGESTIONS_V)

	# zsh-autosuggestions.mk Build cleanup
	rm -rf $(BUILD_DIST)/zsh-autosuggestions

.PHONY: zsh-autosuggestions zsh-autosuggestions-package
