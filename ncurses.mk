ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

NCURSES_VERSION := 6.1
DEB_NCURSES_V   ?= $(NCURSES_VERSION)

ifeq ($(UNAME),Linux)
EXTRA := INSTALL="/usr/bin/install -c --strip-program=$(STRIP)"
else
EXTRA :=
endif

# Needs DESTDIR in make -j8 to not attempt to build test files (which fail to link)
# May need the make clean in between to keep out artifacts from the old DESTDIR

# TODO: Apple vendors ncurses 5.4 but without terminfo. Can we safely upgrade to ncurses 6.x?

# TODO: Is it ok to not include the regular ncurses libraries and instead use ncursesw exclusively?

ifneq ($(wildcard $(BUILD_WORK)/ncurses/.build_complete),)
ncurses:
	@echo "Using previously built ncurses."
else
ncurses: setup
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
		--without-normal \
		--without-debug \
		--enable-sigwinch \
		--disable-mixed-case \
		--enable-termcap \
		--enable-pc-files \
		--with-pkg-config-libdir=/usr/lib/pkgconfig \
		--enable-widec \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/ncurses \
		DESTDIR="$(BUILD_STAGE)/ncurses"
	$(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_STAGE)/ncurses"
	$(MAKE) -C $(BUILD_WORK)/ncurses install \
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
		$(LN) -Tsf "$${ti##*/}" $(BUILD_STAGE)/ncurses/usr/share/terminfo/"$$(printf "%02x" "'$${ti##*/}")" ; \
	done
	
	mkdir -p $(BUILD_STAGE)/ncurses/usr/include/ncursesw
	
	for h in $(BUILD_STAGE)/ncurses/usr/include/*; do \
		if [[ ! -d $$h ]]; then \
			$(LN) -srf $$h $(BUILD_STAGE)/ncurses/usr/include/ncursesw ; \
		fi \
	done

	touch $(BUILD_WORK)/ncurses/.build_complete
endif

ncurses-package: ncurses-stage
	# ncurses.mk Package Structure
	rm -rf $(BUILD_DIST)/ncurses
	mkdir -p $(BUILD_DIST)/ncurses
	
	# ncurses.mk Prep ncurses
	$(FAKEROOT) cp -a $(BUILD_STAGE)/ncurses/usr $(BUILD_DIST)/ncurses
	
	# ncurses.mk Sign
	$(call SIGN,ncurses,general.xml)
	
	# ncurses.mk Make .debs
	$(call PACK,ncurses,DEB_NCURSES_V)
	
	# ncurses.mk Build cleanup
	rm -rf $(BUILD_DIST)/ncurses

.PHONY: ncurses ncurses-package
