ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += fortune-mod
FORTUNE-MOD_VERSION := 3.4.1
DEB_FORTUNE-MOD_V   ?= $(FORTUNE-MOD_VERSION)

fortune-mod-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/shlomif/fortune-mod/releases/download/fortune-mod-$(FORTUNE-MOD_VERSION)/fortune-mod-$(FORTUNE-MOD_VERSION).tar.xz
	$(call EXTRACT_TAR,fortune-mod-$(FORTUNE-MOD_VERSION).tar.xz,fortune-mod-$(FORTUNE-MOD_VERSION),fortune-mod)
	mkdir -p $(BUILD_STAGE)/fortune-mod/usr/{bin,games,share/{games/fortunes/off,man/man{1,6}}}

ifneq ($(wildcard $(BUILD_WORK)/fortune-mod/.build_complete),)
fortune-mod:
	@echo "Using previously built fortune-mod."
else
fortune-mod: .SHELLFLAGS=-O extglob -c
fortune-mod: fortune-mod-setup librecode
	$(SED) -i -e 's|{CMAKE_CURRENT_SOURCE_DIR}/fortune|{CMAKE_CURRENT_SOURCE_DIR}/fortunestuff|' -e 's|fortune/|fortunestuff/|' $(BUILD_WORK)/fortune-mod/CMakeLists.txt
	mv $(BUILD_WORK)/fortune-mod/fortune $(BUILD_WORK)/fortune-mod/fortunestuff
	cd $(BUILD_WORK)/fortune-mod && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DLOCALDIR="/usr/share/games/fortunes" \
		-DLOCALODIR="/usr/share/games/fortunes/off"
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod strfile rot
	clang -I$(BUILD_WORK)/fortune-mod/rinutils/rinutils/include $(BUILD_WORK)/fortune-mod/util/strfile.c -o $(BUILD_WORK)/fortune-mod/strfile
	clang $(BUILD_WORK)/fortune-mod/util/rot.c -o $(BUILD_WORK)/fortune-mod/rot
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod all
	rm -f $(BUILD_WORK)/fortune-mod/{rot,strfile}
	+$(MAKE) -C $(BUILD_WORK)/fortune-mod strfile rot
	cp -a $(BUILD_WORK)/fortune-mod/{rot,strfile,unstr} $(BUILD_STAGE)/fortune-mod/usr/bin
	cp -a $(BUILD_WORK)/fortune-mod/fortune $(BUILD_STAGE)/fortune-mod/usr/games
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/!(CMakeLists.txt|CMakeFiles|Makefile|off) $(BUILD_STAGE)/fortune-mod/usr/share/games/fortunes
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/off/!(CMakeLists.txt|CMakeFiles|Makefile|off|rotated|unrotated) $(BUILD_STAGE)/fortune-mod/usr/share/games/fortunes/off
	cp -a $(BUILD_WORK)/fortune-mod/datfiles/off/rotated/!(PLACEHOLDER) $(BUILD_STAGE)/fortune-mod/usr/share/games/fortunes/off
	cp -a $(BUILD_WORK)/fortune-mod/manpages/fortune.6 $(BUILD_STAGE)/fortune-mod/usr/share/man/man6
	cp -a $(BUILD_WORK)/fortune-mod/util/strfile.man $(BUILD_STAGE)/fortune-mod/usr/share/man/man1/strfile.1
	touch $(BUILD_WORK)/fortune-mod/.build_complete
endif

fortune-mod-package: fortune-mod-stage
	# fortune-mod.mk Package Structure
	rm -rf $(BUILD_DIST)/fortune{-mod,s{,-off}}
	mkdir -p $(BUILD_DIST)/fortune-mod/usr/share \
		$(BUILD_DIST)/fortunes{,-off}/usr/share/games/fortunes
	
	# fortune-mod.mk Prep fortune-mod
	cp -a $(BUILD_STAGE)/fortune-mod/usr/{bin,games} $(BUILD_DIST)/fortune-mod/usr
	cp -a $(BUILD_STAGE)/fortune-mod/usr/share/man $(BUILD_DIST)/fortune-mod/usr/share
	
	# fortune-mod.mk Prep fortunes
	cp -a $(BUILD_STAGE)/fortune-mod/usr/share/games/fortunes/!(off) $(BUILD_DIST)/fortunes/usr/share/games/fortunes
	
	# fortune-mod.mk Prep fortunes-off
	cp -a $(BUILD_STAGE)/fortune-mod/usr/share/games/fortunes/off $(BUILD_DIST)/fortunes-off/usr/share/games/fortunes
	
	# fortune-mod.mk Sign
	$(call SIGN,fortune-mod,general.xml)
	
	# fortune-mod.mk Make .debs
	$(call PACK,fortune-mod,DEB_FORTUNE-MOD_V)
	$(call PACK,fortunes,DEB_FORTUNE-MOD_V)
	$(call PACK,fortunes-off,DEB_FORTUNE-MOD_V)
	
	# fortune-mod.mk Build cleanup
	rm -rf $(BUILD_DIST)/fortune{-mod,s{,-off}}

.PHONY: fortune-mod fortune-mod-package
