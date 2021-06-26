ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fish
FISH_VERSION  := 3.2.2
DEB_FISH_V    ?= $(FISH_VERSION)-1

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
FISH_CMAKE_ARGS := -DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec"
else
FISH_CMAKE_ARGS :=
endif

fish-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/fish-shell/fish-shell/releases/download/$(FISH_VERSION)/fish-$(FISH_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,fish-$(FISH_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,fish-$(FISH_VERSION).tar.xz,fish-$(FISH_VERSION),fish)
	$(SED) -i '/codesign_on_mac/d' $(BUILD_WORK)/fish/CMakeLists.txt
	$(call DO_PATCH,fish,fish,-p1)

ifneq ($(wildcard $(BUILD_WORK)/fish/.build_complete),)
fish:
	@echo "Using previously built fish"
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
fish: fish-setup ncurses gettext pcre2
else
fish: fish-setup ncurses gettext pcre2 libiosexec
endif
	cd $(BUILD_WORK)/fish && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_DOCS=OFF \
		-DGETTEXT_MSGFMT_EXECUTABLE=$(shell which msgfmt) \
		-DCURSES_CURSES_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
		-DCURSES_INCLUDE_PATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/ncursesw" \
		-DSYS_PCRE2_LIB="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpcre2-32.dylib" \
		-DSYS_PCRE2_INCLUDE_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pcre2" \
		-DIntl_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libintl.dylib" \
		-DIntl_INCLUDE_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		-DSED=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$(GNU_PREFIX)sed \
		-Dextra_functionsdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_functions.d \
		-Dextra_completionsdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d \
		-Dextra_confdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/fish/vendor_conf.d \
		-Dmbrtowc_invalid_utf8_exit=0 \
		$(FISH_CMAKE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/fish
	+$(MAKE) -C $(BUILD_WORK)/fish install \
		DESTDIR=$(BUILD_STAGE)/fish
	touch $(BUILD_WORK)/fish/.build_complete
endif

fish-package: fish-stage
	rm -rf $(BUILD_DIST)/fish

	cp -a $(BUILD_STAGE)/fish $(BUILD_DIST)

	$(call SIGN,fish,general.xml)

	$(call PACK,fish,DEB_FISH_V)

	rm -rf $(BUILD_DIST)/fish

.PHONY: fish fish-package
