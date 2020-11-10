ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += ncurses
NCURSES_VERSION := 6.2
DEB_NCURSES_V   ?= $(NCURSES_VERSION)-1

ncurses-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/ncurses/ncurses-$(NCURSES_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,ncurses-$(NCURSES_VERSION).tar.gz)
	$(call EXTRACT_TAR,ncurses-$(NCURSES_VERSION).tar.gz,ncurses-$(NCURSES_VERSION),ncurses)

ifneq ($(wildcard $(BUILD_WORK)/ncurses/.build_complete),)
ncurses:
	@echo "Using previously built ncurses."
else
ncurses: ncurses-setup
	if [ -f $(BUILD_WORK)/ncurses/Makefile ]; then \
		$(MAKE) -C $(BUILD_WORK)/ncurses clean; \
	else \
		:; \
	fi
	cd $(BUILD_WORK)/ncurses && $(EXTRA) \
		./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-build-cc=clang \
		--with-shared \
		--without-debug \
		--enable-sigwinch \
		--enable-const \
		--enable-symlinks \
		--enable-termcap \
		--enable-pc-files \
		--without-x11-rgb \
		--with-pkg-config-libdir=/usr/lib/pkgconfig \
		--enable-widec \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/ncurses
	+$(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_STAGE)/ncurses"
	+$(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_BASE)"
		
	rm $(BUILD_STAGE)/ncurses/usr/bin/tabs
		
	for ti in $(BUILD_STAGE)/ncurses/usr/share/terminfo/*/*; do \
		if [[ $$ti == */@(?(pc)ansi|cons25|cygwin|dumb|linux|mach|rxvt|screen|sun|vt@(52|100|102|220)|swvt25?(m)|[Exe]term|putty|konsole|gnome|apple|Apple_Terminal|unknown)?([-+.]*) ]]; then \
			echo "keeping terminfo: $$ti" ; \
		else \
			rm -f "$$ti" ; \
		fi \
	done

	$(RMDIR) --ignore-fail-on-non-empty $(BUILD_STAGE)/ncurses/usr/share/terminfo/*

	for ti in $(BUILD_STAGE)/ncurses/usr/share/terminfo/*; do \
		if [[ ! -L "$(BUILD_STAGE)/ncurses/usr/share/terminfo/78" ]] && [[ -d "$(BUILD_STAGE)/ncurses/usr/share/terminfo/78" ]]; then \
			LINK=$$(printf "\x$${ti##*/}"); \
		else \
			LINK=$$(printf "%02x" "'$${ti##*/}"); \
		fi; \
		$(LN) -Tsf "$${ti##*/}" $(BUILD_STAGE)/ncurses/usr/share/terminfo/$${LINK}; \
	done
	
	mkdir -p $(BUILD_STAGE)/ncurses/usr/include/ncursesw
	
	for h in $(BUILD_STAGE)/ncurses/usr/include/*; do \
		if [[ ! -d $$h ]]; then \
			$(LN) -srf $$h $(BUILD_STAGE)/ncurses/usr/include/ncursesw ; \
		fi \
	done
	
	mkdir -p $(BUILD_BASE)/usr/include/ncursesw

	for h in $(BUILD_BASE)/usr/include/*; do \
		if [[ ! -d $$h ]]; then \
			$(LN) -srf $$h $(BUILD_BASE)/usr/include/ncursesw ; \
		fi \
	done
	
	for pc in formw menuw ncurses++w ncursesw panelw; do \
		$(SED) -i '/Libs:/c\Libs: -l'$${pc}'' $(BUILD_STAGE)/ncurses/usr/lib/pkgconfig/$${pc}.pc; \
		$(SED) -i '/Libs:/c\Libs: -l'$${pc}'' $(BUILD_BASE)/usr/lib/pkgconfig/$${pc}.pc; \
	done

	touch $(BUILD_WORK)/ncurses/.build_complete
endif

ncurses-package: ncurses-stage
	# ncurses.mk Package Structure
	rm -rf $(BUILD_DIST)/*ncurses*/
	mkdir -p $(BUILD_DIST)/libncursesw6/usr/lib \
		$(BUILD_DIST)/libncurses-dev/usr/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/ncurses-term/usr/{lib,share} \
		$(BUILD_DIST)/ncurses-bin/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/ncurses-doc/usr/share/man
	
	# ncurses.mk Prep libncursesw6
	cp -a $(BUILD_STAGE)/ncurses/usr/lib/lib*.6.dylib $(BUILD_DIST)/libncursesw6/usr/lib
	
	# ncurses.mk Prep libncurses-dev
	cp -a $(BUILD_STAGE)/ncurses/usr/bin/ncurses*-config $(BUILD_DIST)/libncurses-dev/usr/bin
	cp -a $(BUILD_STAGE)/ncurses/usr/share/man/man1/ncurses*-config.1 $(BUILD_DIST)/libncurses-dev/usr/share/man/man1
	cp -a $(BUILD_STAGE)/ncurses/usr/include $(BUILD_DIST)/libncurses-dev/usr
	cp -a $(BUILD_STAGE)/ncurses/usr/lib/!(*.6.*|*.5.*|terminfo) $(BUILD_DIST)/libncurses-dev/usr/lib
	
	# ncurses.mk Prep ncurses-term
	cp -a $(BUILD_STAGE)/ncurses/usr/lib/terminfo $(BUILD_DIST)/ncurses-term/usr/lib
	cp -a $(BUILD_STAGE)/ncurses/usr/share/terminfo $(BUILD_DIST)/ncurses-term/usr/share
	
	# ncurses.mk Prep ncurses-bin
	cp -a $(BUILD_STAGE)/ncurses/usr/bin/!(ncurses*-config) $(BUILD_DIST)/ncurses-bin/usr/bin
	cp -a $(BUILD_STAGE)/ncurses/usr/share/man/man1/!(ncurses*-config.1) $(BUILD_DIST)/ncurses-bin/usr/share/man/man1
	cp -a $(BUILD_STAGE)/ncurses/usr/share/man/man{5,7} $(BUILD_DIST)/ncurses-bin/usr/share/man
	
	# ncurses.mk Prep ncurses-doc
	cp -a $(BUILD_STAGE)/ncurses/usr/share/man/man3 $(BUILD_DIST)/ncurses-doc/usr/share/man
	
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
