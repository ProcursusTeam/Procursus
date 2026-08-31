ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += cmake
CMAKE_VERSION := 3.30.2
DEB_CMAKE_V   ?= $(CMAKE_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
CMAKE_CMAKE_ARGS := -DHAVE_CoreServices:INTERNAL=0
endif

cmake-setup: setup
	$(call GITHUB_ARCHIVE,Kitware,CMake,$(CMAKE_VERSION),v$(CMAKE_VERSION))
	$(call EXTRACT_TAR,cmake-$(CMAKE_VERSION).tar.gz,cmake-$(CMAKE_VERSION),cmake)
	#sed -i "79d" $(BUILD_WORK)/cmake/Source/cmDocumentation.cxx
	#sed -i 's/MAC_OS_X_VERSION_MAX_ALLOWED/9999/' $(BUILD_WORK)/cmake/Source/kwsys/DynamicLoader.{cxx,hxx.in}
	$(call DO_PATCH,cmake,cmake,-p1)

ifneq ($(wildcard $(BUILD_WORK)/cmake/.build_complete),)
cmake:
	@echo "Using previously built cmake."
else
cmake: cmake-setup ncurses libuv1 curl libarchive expat xz nghttp2 zstd
	cd $(BUILD_WORK)/cmake && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_Fortran_COMPILER:FILEPATH=FALSE \
		-DHAVE_POLL_FINE_EXITCODE=1 \
		-DHAVE_POLL_FINE_EXITCODE__TRYRUN_OUTPUT=1 \
		-DBUILD_CursesDialog:BOOL=ON \
		-DCURSES_NCURSES_LIBRARY:FILEPATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
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
		$(CMAKE_CMAKE_ARGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/cmake install \
		DESTDIR="$(BUILD_STAGE)/cmake"
	$(call AFTER_BUILD)
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
