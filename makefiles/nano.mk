ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nano
NANO_VERSION := 7.2
DEB_NANO_V   ?= $(NANO_VERSION)

nano-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/nano/nano-$(NANO_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,nano-$(NANO_VERSION).tar.xz)
	$(call EXTRACT_TAR,nano-$(NANO_VERSION).tar.xz,nano-$(NANO_VERSION),nano)
	$(call DO_PATCH,nano,nano,-p1)

ifneq ($(wildcard $(BUILD_WORK)/nano/.build_complete),)
nano:
	@echo "Using previously built nano."
else
nano: nano-setup ncurses gettext file
	cd $(BUILD_WORK)/nano && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-utf8 \
		--enable-all \
		--disable-debug \
		NCURSESW_LIBS="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib"
	+$(MAKE) -C $(BUILD_WORK)/nano
	+$(MAKE) -C $(BUILD_WORK)/nano install \
		DESTDIR="$(BUILD_STAGE)/nano"
	mkdir -p $(BUILD_STAGE)/nano/$(MEMO_PREFIX){/etc,$(MEMO_SUB_PREFIX)/share/nano/debian}
	cp -a $(BUILD_WORK)/nano/doc/sample.nanorc $(BUILD_STAGE)/nano/$(MEMO_PREFIX)/etc/nanorc
	cp -a $(BUILD_MISC)/nano/debian.nanorc $(BUILD_STAGE)/nano/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/nano/debian/
	$(LN_S) debian/debian.nanorc $(BUILD_STAGE)/nano/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/nano/debian.nanorc
	$(call AFTER_BUILD)
endif

nano-package: nano-stage
	# nano.mk Package Structure
	rm -rf $(BUILD_DIST)/nano
	cp -a $(BUILD_STAGE)/nano $(BUILD_DIST)

	# nano.mk Sign
	$(call SIGN,nano,general.xml)

	# nano.mk Make .debs
	$(call PACK,nano,DEB_NANO_V)

	# nano.mk Build cleanup
	rm -rf $(BUILD_DIST)/nano

.PHONY: nano nano-package
