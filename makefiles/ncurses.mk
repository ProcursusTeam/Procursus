ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS   += ncurses
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS     += ncurses
endif # ($(MEMO_TARGET),darwin-\*)
NCURSES_VERSION := 6.2+20201114
DEB_NCURSES_V   ?= $(NCURSES_VERSION)

ncurses-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/debian/ncurses/-/archive/upstream/$(NCURSES_VERSION)/ncurses-upstream-$(NCURSES_VERSION).tar.gz
	$(call EXTRACT_TAR,ncurses-upstream-$(NCURSES_VERSION).tar.gz,ncurses-upstream-$(NCURSES_VERSION),ncurses)

ifneq ($(wildcard $(BUILD_WORK)/ncurses/.build_complete),)
ncurses:
	@echo "Using previously built ncurses."
else
ncurses: ncurses-setup
	cd $(BUILD_WORK)/ncurses && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-build-cc="$(CC_FOR_BUILD)" \
		--with-build-cpp="$(CPP_FOR_BUILD)" \
		--with-build-cflags="$(CFLAGS_FOR_BUILD)" \
		--with-build-cppflags="$(CPPFLAGS_FOR_BUILD)" \
		--with-build-ldflags="$(LDFLAGS_FOR_BUILD)" \
		--with-shared \
		--without-debug \
		--enable-sigwinch \
		--enable-const \
		--enable-symlinks \
		--enable-termcap \
		--enable-pc-files \
		--without-x11-rgb \
		--with-pkg-config-libdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig \
		--enable-widec \
		--with-default-terminfo-dir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo \
		--with-manpage-format=normal \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/ncurses
	+$(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_STAGE)/ncurses"

	rm $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tabs

ifeq (,$(MEMO_PREFIX))
	for ti in $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/*/*; do \
		if [[ $$ti == */@(?(pc)ansi|cons25|cygwin|dumb|linux|mach|rxvt|screen|sun|vt@(52|100|102|220)|swvt25?(m)|[Exe]term|putty|konsole|gnome|apple|Apple_Terminal|unknown)?([-+.]*) ]]; then \
			echo "keeping terminfo: $$ti" ; \
		else \
			rm -f "$$ti" ; \
		fi \
	done
endif # (/usr,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX))

	rmdir --ignore-fail-on-non-empty $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/*

	for ti in $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/*; do \
		if [[ ! -L "$(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/78" ]] && [[ -d "$(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/78" ]]; then \
			LINK=$$(printf "\x$${ti##*/}"); \
		else \
			LINK=$$(printf "%02x" "'$${ti##*/}"); \
		fi; \
		ln -Tsf "$${ti##*/}" $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo/$${LINK}; \
	done

	for h in $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ncursesw/*; do \
		if [[ ! -d $$h ]]; then \
			$(LN_SR) $$h $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include; \
		fi \
	done

	for pc in formw menuw ncurses++w ncursesw panelw; do \
		sed -i '/Libs:/c\Libs: -l'$${pc}'' $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/$${pc}.pc; \
	done

	for file in form menu ncurses panel; do \
		$(LN_S) $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib$${file}w.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib$${file}.dylib; \
	done
	$(LN_S) $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcurses.dylib

	$(call AFTER_BUILD,copy)
endif

ncurses-package: ncurses-stage
	# ncurses.mk Package Structure
	rm -rf $(BUILD_DIST)/*ncurses*/
	mkdir -p $(BUILD_DIST)/libncursesw6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libncurses-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/ncurses-term/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/ncurses-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/ncurses-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# ncurses.mk Prep libncursesw6
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib*.6.dylib $(BUILD_DIST)/libncursesw6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ncurses.mk Prep libncurses-dev
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ncurses*-config $(BUILD_DIST)/libncurses-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/ncurses*-config.1 $(BUILD_DIST)/libncurses-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libncurses-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.6.*|*.5.*|terminfo) $(BUILD_DIST)/libncurses-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ncurses.mk Prep ncurses-term
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/terminfo $(BUILD_DIST)/ncurses-term/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/terminfo $(BUILD_DIST)/ncurses-term/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# ncurses.mk Prep ncurses-bin
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(ncurses*-config) $(BUILD_DIST)/ncurses-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/!(ncurses*-config.1) $(BUILD_DIST)/ncurses-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{5,7} $(BUILD_DIST)/ncurses-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# ncurses.mk Prep ncurses-doc
	cp -a $(BUILD_STAGE)/ncurses/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/ncurses-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# ncurses.mk Sign
	$(call SIGN,libncursesw6,general.xml)
	$(call SIGN,ncurses-bin,general.xml)

	# ncurses.mk Make .debs
	$(call PACK,libncursesw6,DEB_NCURSES_V)
	$(call PACK,libncurses-dev,DEB_NCURSES_V)
	$(call PACK,ncurses-term,DEB_NCURSES_V)
	$(call PACK,ncurses-bin,DEB_NCURSES_V)
	$(call PACK,ncurses-doc,DEB_NCURSES_V)

	# ncurses.mk Build cleanup
	rm -rf $(BUILD_DIST)/*ncurses*/

.PHONY: ncurses ncurses-package
