ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifeq ($(UNAME),Linux)
EXTRA := INSTALL="/usr/bin/install -c --strip-program=$(TRIPLE)strip"
else
EXTRA :=
endif

# Needs DESTDIR in make -j8 to not attempt to build test files (which fail to link)
# May need the make clean in between to keep out artifacts from the old DESTDIR

# TODO: Apple vendors ncurses 5.4 but without terminfo. Can we safely upgrade to ncurses 6.x?

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
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/ncurses \
		DESTDIR="$(BUILD_STAGE)/ncurses"
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_STAGE)/ncurses"
	$(MAKE) -C $(BUILD_WORK)/ncurses install \
		DESTDIR="$(BUILD_BASE)"

.PHONY: ncurses
