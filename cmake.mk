ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cmake
CMAKE_VERSION := 3.18.1
DEB_CMAKE_V   ?= $(CMAKE_VERSION)

cmake-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Kitware/CMake/releases/download/v$(CMAKE_VERSION)/cmake-$(CMAKE_VERSION).tar.gz
	$(call EXTRACT_TAR,cmake-$(CMAKE_VERSION).tar.gz,cmake-$(CMAKE_VERSION),cmake)
	$(SED) -i 's|#if !defined(CMAKE_BOOTSTRAP) \&\& defined(__APPLE__)|#if 0|' $(BUILD_WORK)/cmake/Source/cmGlobalXCodeGenerator.cxx

ifneq ($(wildcard $(BUILD_WORK)/cmake/.build_complete),)
cmake:
	@echo "Using previously built cmake."
else
cmake: cmake-setup ncurses
	cd $(BUILD_WORK)/cmake && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DCMAKE_Fortran_COMPILER:FILEPATH=FALSE \
		-DHAVE_POLL_FINE_EXITCODE=1 \
		-DHAVE_POLL_FINE_EXITCODE__TRYRUN_OUTPUT=1 \
		-DHAVE_CoreServices:INTERNAL=0 \
		-DBUILD_CursesDialog:BOOL=ON \
		-DCURSES_NCURSES_LIBRARY:FILEPATH="$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
		-DSPHINX_MAN:BOOL=ON \
		.
	+$(MAKE) -C $(BUILD_WORK)/cmake install \
		DESTDIR="$(BUILD_STAGE)/cmake"
	touch $(BUILD_WORK)/cmake/.build_complete
endif

cmake-package: cmake-stage
	# cmake.mk Package Structure
	rm -rf $(BUILD_DIST)/cmake{,-data,-curses-gui}
	mkdir -p $(BUILD_DIST)/cmake{,-curses-gui}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/cmake-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	
	# cmake.mk Prep cmake
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(ccmake) $(BUILD_DIST)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man/man1/!(ccmake.1) $(BUILD_DIST)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# cmake.mk Prep cmake-curses-gui
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ccmake $(BUILD_DIST)/cmake-curses-gui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man/man1/ccmake.1 $(BUILD_DIST)/cmake-curses-gui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# cmake.mk Prep cmake-data
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man/man7 $(BUILD_DIST)/cmake-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/cmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{aclocal,bash-completion,cmake-*,emacs,vim} $(BUILD_DIST)/cmake-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	
	# cmake.mk Sign
	$(call SIGN,cmake,general.xml)
	$(call SIGN,cmake-curses-gui,general.xml)
	
	# cmake.mk Make .debs
	$(call PACK,cmake,DEB_CMAKE_V)
	$(call PACK,cmake-curses-gui,DEB_CMAKE_V)
	$(call PACK,cmake-data,DEB_CMAKE_V)
	
	# cmake.mk Build cleanup
	rm -rf $(BUILD_DIST)/cmake{,-data,-curses-gui}

.PHONY: cmake cmake-package
