ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += moon-buggy
MOON-BUGGY_VERSION := 1.0.51
DEB_MOON-BUGGY_V   ?= $(MOON-BUGGY_VERSION)-1

moon-buggy-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://m.seehuhn.de/programs/moon-buggy-$(MOON-BUGGY_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,moon-buggy-$(MOON-BUGGY_VERSION).tar.gz)
	$(call EXTRACT_TAR,moon-buggy-$(MOON-BUGGY_VERSION).tar.gz,moon-buggy-$(MOON-BUGGY_VERSION),moon-buggy)
	$(CP) -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/moon-buggy
	$(SED) -i 's|$$(DESTDIR)$$(bindir)/moon-buggy -c||' $(BUILD_WORK)/moon-buggy/Makefile.am

ifneq ($(wildcard $(BUILD_WORK)/moon-buggy/.build_complete),)
moon-buggy:
	@echo "Using previously built moon-buggy."
else
moon-buggy: moon-buggy-setup ncurses
	cd $(BUILD_WORK)/moon-buggy && autoreconf -fi
	cd $(BUILD_WORK)/moon-buggy && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-curses-lib="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/moon-buggy \
		moon_buggy_LDADD="-lncursesw" \
		CURSES_LIBS="-lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/moon-buggy install \
		DESTDIR="$(BUILD_STAGE)/moon-buggy"
	touch $(BUILD_WORK)/moon-buggy/.build_complete
endif

moon-buggy-package: moon-buggy-stage
	# moon-buggy.mk Package Structure
	rm -rf $(BUILD_DIST)/moon-buggy

	# moon-buggy.mk Prep moon-buggy
	cp -a $(BUILD_STAGE)/moon-buggy $(BUILD_DIST)

	# moon-buggy.mk Sign
	$(call SIGN,moon-buggy,general.xml)

	# moon-buggy.mk Make .debs
	$(call PACK,moon-buggy,DEB_MOON-BUGGY_V)

	# moon-buggy.mk Build cleanup
	rm -rf $(BUILD_DIST)/moon-buggy

.PHONY: moon-buggy moon-buggy-package
