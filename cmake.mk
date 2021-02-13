ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cmake
CMAKE_VERSION := 3.19.4
DEB_CMAKE_V   ?= $(CMAKE_VERSION)

cmake-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Kitware/CMake/releases/download/v$(CMAKE_VERSION)/cmake-$(CMAKE_VERSION).tar.gz
	$(call EXTRACT_TAR,cmake-$(CMAKE_VERSION).tar.gz,cmake-$(CMAKE_VERSION),cmake)
	$(call DO_PATCH,cmake,cmake,-p1) # Remove when cmake 3.20.0 releases.

ifneq ($(wildcard $(BUILD_WORK)/cmake/.build_complete),)
cmake:
	@echo "Using previously built cmake."
else
cmake: cmake-setup ncurses libuv1 curl libarchive expat xz nghttp2 zstd
	cd $(BUILD_WORK)/cmake && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DCMAKE_Fortran_COMPILER:FILEPATH=FALSE \
		-DHAVE_POLL_FINE_EXITCODE=1 \
		-DHAVE_POLL_FINE_EXITCODE__TRYRUN_OUTPUT=1 \
		-DHAVE_CoreServices:INTERNAL=0 \
		-DBUILD_CursesDialog:BOOL=ON \
		-DCURSES_NCURSES_LIBRARY:FILEPATH="$(BUILD_BASE)/usr/lib/libncursesw.dylib" \
		-DSPHINX_MAN:BOOL=ON \
		-DCMAKE_USE_SYSTEM_LIBUV=ON \
		-DCMAKE_USE_SYSTEM_BZIP2=ON \
		-DCMAKE_USE_SYSTEM_CURL=ON \
		-DCMAKE_USE_SYSTEM_EXPAT=ON \
		-DCMAKE_USE_SYSTEM_LIBARCHIVE=ON \
		-DCMAKE_USE_SYSTEM_LIBLZMA=ON \
		-DCMAKE_USE_SYSTEM_NGHTTP2=ON \
		-DCMAKE_USE_SYSTEM_ZLIB=ON \
		-DCMAKE_USE_SYSTEM_ZSTD=ON \
		.
	+$(MAKE) -C $(BUILD_WORK)/cmake install \
		DESTDIR="$(BUILD_STAGE)/cmake"
	touch $(BUILD_WORK)/cmake/.build_complete
endif

cmake-package: cmake-stage
	# cmake.mk Package Structure
	rm -rf $(BUILD_DIST)/cmake{,-data,-curses-gui}
	mkdir -p $(BUILD_DIST)/cmake{,-curses-gui}/usr/{bin,share/man/man1} \
		$(BUILD_DIST)/cmake-data/usr/share/man
	
	# cmake.mk Prep cmake
	cp -a $(BUILD_STAGE)/cmake/usr/bin/!(ccmake) $(BUILD_DIST)/cmake/usr/bin
	cp -a $(BUILD_STAGE)/cmake/usr/man/man1/!(ccmake.1) $(BUILD_DIST)/cmake/usr/share/man/man1

	# cmake.mk Prep cmake-curses-gui
	cp -a $(BUILD_STAGE)/cmake/usr/bin/ccmake $(BUILD_DIST)/cmake-curses-gui/usr/bin
	cp -a $(BUILD_STAGE)/cmake/usr/man/man1/ccmake.1 $(BUILD_DIST)/cmake-curses-gui/usr/share/man/man1

	# cmake.mk Prep cmake-data
	cp -a $(BUILD_STAGE)/cmake/usr/man/man7 $(BUILD_DIST)/cmake-data/usr/share/man
	cp -a $(BUILD_STAGE)/cmake/usr/share/{aclocal,bash-completion,cmake-*,emacs,vim} $(BUILD_DIST)/cmake-data/usr/share
	
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
