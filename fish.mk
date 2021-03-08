ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fish
FISH_VERSION  := 3.1.2
DEB_FISH_V    ?= $(FISH_VERSION)

fish-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/fish-shell/fish-shell/releases/download/$(FISH_VERSION)/fish-$(FISH_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,fish-$(FISH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,fish-$(FISH_VERSION).tar.gz,fish-$(FISH_VERSION),fish)
	$(SED) -i -e '168,180d' -e '/codesign/Id' $(BUILD_WORK)/fish/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/fish/.build_complete),)
fish:
	@echo "Using previously built fish"
else
fish: fish-setup ncurses gettext pcre2
	cd $(BUILD_WORK)/fish && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)" \
		-DCMAKE_LIBRARY_PATH="$(BUILD_BASE)/usr/lib" \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_CROSSCOMPILING=true \
		-DCURSES_CURSES_LIBRARY="$(BUILD_BASE)/usr/lib/libncursesw.dylib" \
		-DCURSES_INCLUDE_PATH="$(BUILD_BASE)/usr/include/ncursesw" \
		-DPCRE2_LIB="$(BUILD_BASE)/usr/lib/libpcre2-32.dylib" \
		-DPCRE2_INCLUDE_DIR="$(BUILD_BASE)/usr/include/pcre2" \
		-DSED=/usr/bin/sed \
		-DCMAKE_INSTALL_SYSCONFDIR=/etc \
		-Dextra_functionsdir=/usr/share/fish/vendor_functions.d \
		-Dextra_completionsdir=/usr/share/fish/vendor_completions.d \
		-Dextra_confdir=/usr/share/fish/vendor_conf.d
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
