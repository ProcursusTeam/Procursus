ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += fortune-mod
FORTUNE-MOD_VERSION := 3.6.0
DEB_FORTUNE-MOD_V   ?= $(FORTUNE-MOD_VERSION)

fortune-mod-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/shlomif/fortune-mod/releases/download/fortune-mod-$(FORTUNE-MOD_VERSION)/fortune-mod-$(FORTUNE-MOD_VERSION).tar.xz
	$(call EXTRACT_TAR,fortune-mod-$(FORTUNE-MOD_VERSION).tar.xz,fortune-mod-$(FORTUNE-MOD_VERSION),fortune-mod)
	mkdir -p $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,games,share/{games/fortunes/off,man/man{1,6}}}

ifneq ($(wildcard $(BUILD_WORK)/fortune-mod/.build_complete),)
fortune-mod:
	@echo "Using previously built fortune-mod."
else
fortune-mod: .SHELLFLAGS=-O extglob -c
fortune-mod: fortune-mod-setup librecode
	$(SED) -i -e 's|{CMAKE_CURRENT_SOURCE_DIR}/fortune|{CMAKE_CURRENT_SOURCE_DIR}/fortunestuff|' -e 's|fortune/|fortunestuff/|' $(BUILD_WORK)/fortune-mod/CMakeLists.txt
	mv $(BUILD_WORK)/fortune-mod/fortune $(BUILD_WORK)/fortune-mod/fortunestuff
	cd $(BUILD_WORK)/fortune-mod && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DLOCALDIR="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes" \
		-DLOCALODIR="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes/off"
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod strfile rot
	clang -I$(BUILD_WORK)/fortune-mod/rinutils/rinutils/include $(BUILD_WORK)/fortune-mod/util/strfile.c -o $(BUILD_WORK)/fortune-mod/strfile
	clang $(BUILD_WORK)/fortune-mod/util/rot.c -o $(BUILD_WORK)/fortune-mod/rot
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod all
	rm -f $(BUILD_WORK)/fortune-mod/{rot,strfile}
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod strfile rot
	cp -a $(BUILD_WORK)/fortune-mod/{rot,strfile,unstr} $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/fortune-mod/fortune $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/games
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/!(CMakeLists.txt|CMakeFiles|Makefile|off) $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/off/!(CMakeLists.txt|CMakeFiles|Makefile|off|rotated|unrotated) $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes/off
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/off/rotated/!(PLACEHOLDER) $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes/off
	cp -a $(BUILD_WORK)/fortune-mod/manpages/fortune.6 $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man6
	cp -a $(BUILD_WORK)/fortune-mod/util/strfile.man $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/strfile.1
	touch $(BUILD_WORK)/fortune-mod/.build_complete
endif

fortune-mod-package: fortune-mod-stage
	# fortune-mod.mk Package Structure
	rm -rf $(BUILD_DIST)/fortune{-mod,s{,-off}}
	mkdir -p $(BUILD_DIST)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/fortunes{,-off}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes

	# fortune-mod.mk Prep fortune-mod
	cp -a $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,games} $(BUILD_DIST)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# fortune-mod.mk Prep fortunes
	cp -a $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes/!(off) $(BUILD_DIST)/fortunes/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes

	# fortune-mod.mk Prep fortunes-off
	cp -a $(BUILD_STAGE)/fortune-mod/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes/off $(BUILD_DIST)/fortunes-off/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/fortunes

	# fortune-mod.mk Sign
	$(call SIGN,fortune-mod,general.xml)

	# fortune-mod.mk Make .debs
	$(call PACK,fortune-mod,DEB_FORTUNE-MOD_V)
	$(call PACK,fortunes,DEB_FORTUNE-MOD_V)
	$(call PACK,fortunes-off,DEB_FORTUNE-MOD_V)

	# fortune-mod.mk Build cleanup
	rm -rf $(BUILD_DIST)/fortune{-mod,s{,-off}}

.PHONY: fortune-mod fortune-mod-package
