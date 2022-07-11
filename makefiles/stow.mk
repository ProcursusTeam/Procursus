ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += stow
STOW_VERSION := 2.3.1
DEB_STOW_V   ?= $(STOW_VERSION)

stow-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftp.gnu.org/gnu/stow/stow-$(STOW_VERSION).tar.gz)
	$(call EXTRACT_TAR,stow-$(STOW_VERSION).tar.gz,stow-$(STOW_VERSION),stow)

ifneq ($(wildcard $(BUILD_WORK)/stow/.build_complete),)
stow:
	@echo "Using previously built stow."
else
stow: stow-setup
	cd $(BUILD_WORK)/stow && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pmdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		PERL="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl"
	+$(MAKE) -C $(BUILD_WORK)/stow
	+$(MAKE) -C $(BUILD_WORK)/stow install \
		DESTDIR="$(BUILD_STAGE)/stow"
	$(call AFTER_BUILD)
endif

stow-package: stow-stage
	# stow.mk Package Structure
	rm -rf $(BUILD_DIST)/stow

	# stow.mk Prep stow
	cp -a $(BUILD_STAGE)/stow $(BUILD_DIST)

	# stow.mk Make .debs
	$(call PACK,stow,DEB_STOW_V)

	# stow.mk Build cleanup
	rm -rf $(BUILD_DIST)/stow

.PHONY: stow stow-package
