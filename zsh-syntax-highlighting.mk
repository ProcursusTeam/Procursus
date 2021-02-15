ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                     += zsh-syntax-highlighting
ZSH-SYNTAX-HIGHLIGHTING_VERSION := 0.7.1
DEB_ZSH-SYNTAX-HIGHLIGHTING_V   ?= $(ZSH-SYNTAX-HIGHLIGHTING_VERSION)

zsh-syntax-highlighting-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/zsh-syntax-highlighting-$(ZSH-SYNTAX-HIGHLIGHTING_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/zsh-syntax-highlighting-$(ZSH-SYNTAX-HIGHLIGHTING_VERSION).tar.gz \
			https://github.com/zsh-users/zsh-syntax-highlighting/archive/$(ZSH-SYNTAX-HIGHLIGHTING_VERSION).tar.gz
	$(call EXTRACT_TAR,zsh-syntax-highlighting-$(ZSH-SYNTAX-HIGHLIGHTING_VERSION).tar.gz,zsh-syntax-highlighting-$(ZSH-SYNTAX-HIGHLIGHTING_VERSION),zsh-syntax-highlighting)

ifneq ($(wildcard $(BUILD_WORK)/zsh-syntax-highlighting/.build_complete),)
zsh-syntax-highlighting:
	@echo "Using previously built zsh-syntax-highlighting."
else
zsh-syntax-highlighting: zsh-syntax-highlighting-setup ncurses gettext file
	+$(MAKE) -C $(BUILD_WORK)/zsh-syntax-highlighting install \
		PREFIX='$(BUILD_STAGE)/zsh-syntax-highlighting/usr'
	touch $(BUILD_WORK)/zsh-syntax-highlighting/.build_complete
endif

zsh-syntax-highlighting-package: zsh-syntax-highlighting-stage
	# zsh-syntax-highlighting.mk Package Structure
	rm -rf $(BUILD_DIST)/zsh-syntax-highlighting
	mkdir -p $(BUILD_DIST)/zsh-syntax-highlighting
	
	# zsh-syntax-highlighting.mk Prep zsh-syntax-highlighting
	cp -a $(BUILD_STAGE)/zsh-syntax-highlighting $(BUILD_DIST)
	
	# zsh-syntax-highlighting.mk Make .debs
	$(call PACK,zsh-syntax-highlighting,DEB_ZSH-SYNTAX-HIGHLIGHTING_V)
	
	# zsh-syntax-highlighting.mk Build cleanup
	rm -rf $(BUILD_DIST)/zsh-syntax-highlighting

.PHONY: zsh-syntax-highlighting zsh-syntax-highlighting-package
