ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fish
FISH_VERSION  := 3.7.1
DEB_FISH_V    ?= $(FISH_VERSION)

fish-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/fish-shell/fish-shell/releases/download/$(FISH_VERSION)/fish-$(FISH_VERSION).tar.xz{$(comma).asc})
	$(call PGP_VERIFY,fish-$(FISH_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,fish-$(FISH_VERSION).tar.xz,fish-$(FISH_VERSION),fish)
	sed -i '/codesign_on_mac/d' $(BUILD_WORK)/fish/CMakeLists.txt
	rm -f $(BUILD_WORK)/fish/version # The C++ standards people truly put no thought into add version as a libc++ header

ifneq ($(wildcard $(BUILD_WORK)/fish/.build_complete),)
fish:
	@echo "Using previously built fish"
else
fish: fish-setup ncurses gettext pcre2
	cd $(BUILD_WORK)/fish && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS) -std=c++11" \
		-DBUILD_DOCS=OFF \
		-DGETTEXT_MSGFMT_EXECUTABLE=$(shell command -v msgfmt) \
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
	$(call AFTER_BUILD)
endif

fish-package: fish-stage
	rm -rf $(BUILD_DIST)/fish

	cp -a $(BUILD_STAGE)/fish $(BUILD_DIST)

	$(call SIGN,fish,general.xml)

	$(call PACK,fish,DEB_FISH_V)

	rm -rf $(BUILD_DIST)/fish

.PHONY: fish fish-package
