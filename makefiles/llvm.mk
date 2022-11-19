ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#### Consider mlir/pstl/flang too

SUBPROJECTS     += llvm
LLVM_MAJOR_V    := 14
LLVM_MINOR_V    := 0
LLVM_PATCH_V    := 0
LLVM_VERSION    := $(LLVM_MAJOR_V).$(LLVM_MINOR_V).$(LLVM_PATCH_V)
LLVM_REVISION   := 3dade082a9b1989207a7fa7f3975868485d16a49
LLVM_REPOSITORY := https://github.com/apple/llvm-project.git
SWIFT_VERSION   := 5.7.1
SWIFT_SUFFIX    := RELEASE
DEB_SWIFT_V     ?= $(SWIFT_VERSION)~$(SWIFT_SUFFIX)
DEB_LLVM_V      ?= $(LLVM_VERSION)~$(DEB_SWIFT_V)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LLVM_CMAKE_FLAGS :=     -DLLDB_USE_SYSTEM_DEBUGSERVER=ON \
			-DLLVM_CREATE_XCODE_TOOLCHAIN=OFF
else
LLVM_CMAKE_FLAGS :=     -DAPPLE_EMBEDDED=$(MEMO_TARGET) \
			-DLLDB_USE_SYSTEM_DEBUGSERVER=OFF
endif

llvm-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/apple/llvm-project/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz)
	$(call GITHUB_ARCHIVE,apple,swift,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-swift)
	$(call GITHUB_ARCHIVE,apple,cmark,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-cmark)
	$(call EXTRACT_TAR,swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,llvm-project-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm)
	$(call EXTRACT_TAR,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/swift)
	$(call EXTRACT_TAR,swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-cmark-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/cmark)
	$(call DO_PATCH,llvm,llvm,-p1)
	$(call DO_PATCH,swift,llvm/swift,-p1)
	mkdir -p $(BUILD_WORK)/llvm/build
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's|isysroot $${CMAKE_OSX_SYSROOT}|isysroot $${CMAKE_FIND_ROOT_PATH}|' $(BUILD_WORK)/llvm/lldb/tools/debugserver/source/CMakeLists.txt
endif

ifneq ($(wildcard $(BUILD_WORK)/llvm/.build_complete),)
llvm:
	@echo "Using previously built llvm."
else
llvm: llvm-setup libffi libedit ncurses xz xar
#	Temporary SED until swift can build on their own apple silicon (cmon apple)
	sed -i -e 's/aarch64|ARM64/aarch64|ARM64|arm64/' -e 's/SWIFT_HOST_VARIANT_ARCH_default "aarch64"/SWIFT_HOST_VARIANT_ARCH_default "arm64"/' $(BUILD_WORK)/llvm/swift/CMakeLists.txt

ifeq ($(wildcard $(BUILD_WORK)/../../native/llvm/.build_complete),)
	mkdir -p $(BUILD_WORK)/../../native/llvm && cd $(BUILD_WORK)/../../native/llvm && unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && cmake . \
		-DCMAKE_C_COMPILER=cc \
		-DCMAKE_CXX_COMPILER=c++ \
		-DCMAKE_C_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)" \
		-DSWIFT_INCLUDE_TESTS=OFF \
		-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
		-DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
		-DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lldb" \
		-DLLVM_EXTERNAL_PROJECTS="cmark;swift" \
		-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR="$(BUILD_WORK)/llvm/swift" \
		-DLLVM_EXTERNAL_CMARK_SOURCE_DIR="$(BUILD_WORK)/llvm/cmark" \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=FALSE \
		$(BUILD_WORK)/llvm/llvm
	mkdir -p $(BUILD_WORK)/../../native/llvm/share/swift # ¯\_(ツ)_/¯
	+$(MAKE) -C $(BUILD_WORK)/../../native/llvm swift-components lldb-tblgen
	touch $(BUILD_WORK)/../../native/llvm/.build_complete
endif

ifeq ($(wildcard $(BUILD_WORK)/llvm/build/.build_complete),)
	case $(MEMO_TARGET) in \
	*"darwin"*) \
		SWIFT_VARIANT=OSX \
		;; \
	*"iphoneos"*) \
		SWIFT_VARIANT=IOS \
		;; \
	*"tvos"*) \
		SWIFT_VARIANT=TVOS \
		;; \
	*"watchos"*) \
		SWIFT_VARIANT=TVOS \
		;; \
	esac; \
	cd $(BUILD_WORK)/llvm/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		$(LLVM_CMAKE_FLAGS) \
		-DLLVM_REVISION=$(LLVM_REVISION) \
		-DLLVM_REPOSITORY=$(LLVM_REPOSITORY) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DLIBCXX_INSTALL_LIBRARY_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/c++" \
		-DLIBCXXABI_INSTALL_LIBRARY_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/c++" \
		-DLLVM_ENABLE_FFI=ON \
		-DLLVM_ENABLE_RTTI=ON \
		-DLLVM_ENABLE_EH=ON \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="$(CFLAGS_FOR_BUILD)";-DCMAKE_CXX_FLAGS="$(CXXFLAGS_FOR_BUILD)";-DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS_FOR_BUILD)"' \
		-DCLANG_VERSION=$(LLVM_VERSION) \
		-DLLVM_ENABLE_LTO=THIN \
		-DLLVM_BUILD_LLVM_DYLIB=ON \
		-DLLVM_LINK_LLVM_DYLIB=ON \
		-DCLANG_LINK_CLANG_DYLIB=ON \
		-DLIBCXX_OVERRIDE_DARWIN_INSTALL=ON \
		-DLLVM_VERSION_MAJOR=$(LLVM_MAJOR_V) \
		-DLLVM_VERSION_MINOR=$(LLVM_MINOR_V) \
		-DLLVM_VERSION_PATCH=$(LLVM_PATCH_V) \
		-DLLVM_VERSION_SUFFIX="" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_TARGET) \
		-DLLVM_TARGET_TRIPLE_ENV="LLVM_TARGET_TRIPLE" \
		-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
		-DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lldb;clang-tools-extra;lld;polly" \
		-DLLVM_EXTERNAL_PROJECTS="cmark;swift" \
		-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR="$(BUILD_WORK)/llvm/swift" \
		-DLLVM_EXTERNAL_CMARK_SOURCE_DIR="$(BUILD_WORK)/llvm/cmark" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DMIG_ARCHS=$(MEMO_ARCH) \
		-DCFLAGS_DEPLOYMENT_VERSION_IOS="$(IPHONEOS_DEPLOYMENT_TARGET)" \
		-DCFLAGS_DEPLOYMENT_VERSION_TVOS="$(APPLETVOS_DEPLYMENT_TARGET)" \
		-DCFLAGS_DEPLOYMENT_VERSION_WATCHOS="$(WATCHOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_PRIMARY_VARIANT_ARCH="$(MEMO_ARCH)" \
		-DSWIFT_PRIMARY_VARIANT_SDK=$${SWIFT_VARIANT} \
		-DSWIFT_HOST_VARIANT="$(PLATFORM)" \
		-DSWIFT_HOST_VARIANT_ARCH="$(MEMO_ARCH)" \
		-DCFLAGS_SDK=$${SWIFT_VARIANT} \
		-DSWIFT_HOST_VARIANT_SDK=$${SWIFT_VARIANT} \
		-DSWIFT_ENABLE_IOS32=OFF \
		-DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=ON \
		-DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=ON \
		-DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=ON \
		-DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=ON \
		-DSWIFT_INCLUDE_TESTS=OFF \
		-DSWIFT_TOOLS_ENABLE_LTO=THIN \
		-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
		-DSWIFT_NATIVE_SWIFT_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DSWIFT_NATIVE_CLANG_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DSWIFT_NATIVE_LLVM_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DLLVM_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/llvm-tblgen" \
		-DCLANG_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/clang-tblgen" \
		-DLLDB_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" \
		-DLLDB_TABLEGEN_EXE="$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" \
		-DLLDB_BUILD_FRAMEWORK=OFF \
		-DLLDB_ENABLE_LUA=OFF \
		-DLLDB_ENABLE_PYTHON=OFF \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_IOS="$(IPHONEOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX="$(MACOSX_DEPLYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_WATCHOS="$(WATCHOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_TVOS="$(APPLETVOS_DEPLYMENT_TARGET)" \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=FALSE \
		-DPACKAGE_VENDOR="Procursus" \
		-DBUG_REPORT_URL="https://github.com/ProcursusTeam/Procursus/issues" \
		../llvm
	mkdir -p $(BUILD_WORK)/llvm/build/share/swift # ¯\_(ツ)_/¯
	+$(MAKE) -C $(BUILD_WORK)/llvm/build
	+$(MAKE) -C $(BUILD_WORK)/llvm/build install \
		DESTDIR="$(BUILD_STAGE)/llvm"
	$(INSTALL) -Dm755 $(BUILD_WORK)/llvm/build/bin/{obj2yaml,yaml2obj} $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/
	touch $(BUILD_WORK)/llvm/build/.build_complete
endif
	# Now we compile compiler-rt.
	# We do it seperately because CMake will set the correct flags for cross compiling for us,
	# which we will conflict with.
	mkdir -p $(BUILD_WORK)/llvm/build-compiler-rt && cd $(BUILD_WORK)/llvm/build-compiler-rt && unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && cmake . \
		-DCMAKE_C_COMPILER="cc" \
		-DCMAKE_CXX_COMPILER="c++" \
		-DCMAKE_C_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		$(BUILD_WORK)/llvm/llvm
	+unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET APPLETVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET && \
		$(MAKE) -C $(BUILD_WORK)/llvm/build-compiler-rt install-compiler-rt \
		DESTDIR="$(BUILD_STAGE)/llvm"
	# Let's build wrappers now
	mkdir -p $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_MISC)/llvm/wrapper.c -o $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-$(LLVM_MAJOR_V) \
		-DTOOL=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang\" -DDEFAULT_SYSROOT=\"$(ON_DEVICE_SDK_PATH)\" \
		-DEXTRA_CPATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include\" -DEXTRA_LIBRARY_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib\"
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_MISC)/llvm/wrapper.c -o $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang++-$(LLVM_MAJOR_V) \
		-DTOOL=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang++\" -DDEFAULT_SYSROOT=\"$(ON_DEVICE_SDK_PATH)\" \
		-DEXTRA_CPATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include\" -DEXTRA_LIBRARY_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib\"
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_MISC)/llvm/wrapper.c -o $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cpp-$(LLVM_MAJOR_V) \
		-DTOOL=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang-cpp\" -DDEFAULT_SYSROOT=\"$(ON_DEVICE_SDK_PATH)\" \
		-DEXTRA_CPATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include\" -DEXTRA_LIBRARY_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib\"
	$(call AFTER_BUILD,,,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib)
endif

llvm-package: llvm-stage
	# llvm.mk Package Structure
	rm -rf $(BUILD_DIST)/{clang*,debugserver*,libc++*,libclang*,liblldb*,liblld*,libllvm*,lldb*,swift*,lld*,llvm*}/

	# llvm.mk Prep clang-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib/cmake,share/clang}}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang{,-$(LLVM_MAJOR_V),++,-cpp} $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang/bash-autocomplete.sh $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake/clang $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang{,++,-cpp}-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/

	# llvm.mk Prep clang
	mkdir -p $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) clang-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang
	$(LN_S) clang++-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang++
	$(LN_S) clang $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cc
	$(LN_S) clang++ $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/c++
	$(LN_S) clang-cpp-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cpp

	# llvm.mk Prep clang-format-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{,git-}clang-format $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep clang-format
	mkdir -p $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-format $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-format
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/git-clang-format $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/git-clang-format

	# llvm.mk Prep clang-tidy-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang-tidy $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep clang-tidy
	mkdir -p $(BUILD_DIST)/clang-tidy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-tidy $(BUILD_DIST)/clang-tidy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-tidy

	# llvm.mk Prep clangd-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clangd $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clangd $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clangd-$(LLVM_MAJOR_V)

	# llvm.mk Prep clangd
	mkdir -p $(BUILD_DIST)/clangd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) clangd-$(LLVM_MAJOR_V) $(BUILD_DIST)/clangd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clangd

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	# llvm.mk Prep debugserver-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver-$(LLVM_MAJOR_V)

	# llvm.mk Prep debugserver
	mkdir -p $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver
endif

	# llvm.mk Prep libc++-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/c++ $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include

	# llvm.mk Prep libc++-dev
	mkdir -p $(BUILD_DIST)/libc++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/include/c++ $(BUILD_DIST)/libc++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++

	# llvm.mk Prep libclang-common-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{,llvm-$(LLVM_MAJOR_V)/lib/}clang
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libPolly{,ISL}.a $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/clang/$(LLVM_VERSION) $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/clang
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/polly $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake/polly $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake
	$(LN_S) ../llvm-$(LLVM_MAJOR_V)/lib/clang/$(LLVM_VERSION) $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/clang

	# llvm.mk Prep libclang-cpp$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libclang-cpp$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libclang-cpp*.dylib $(BUILD_DIST)/libclang-cpp$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep libclang1-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libclang1-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libclang.dylib $(BUILD_DIST)/libclang1-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	$(LN_S) libclang.dylib $(BUILD_DIST)/libclang1-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libclang-$(LLVM_MAJOR_V).dylib

	# llvm.mk Prep libclang-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libclang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib}
	for lib in $$(find $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib -name "libclang*" -and -name "*.a"); do \
		cp -a $$lib $(BUILD_DIST)/libclang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib; \
	done
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/clang{,-c,-tidy} $(BUILD_DIST)/libclang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include

	# llvm.mk Prep liblldb-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/liblldb.$(LLVM_VERSION).dylib $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep liblldb-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/lldb $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	$(LN_S) liblldb.$(LLVM_VERSION).dylib $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/liblldb.dylib

	# llvm.mk Prep liblld-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/liblld* $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	rm $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/liblldb*

	# llvm.mk Prep liblld-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib/cmake}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/lld $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake/lld $(BUILD_DIST)/liblld-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake

	# llvm.mk Prep libllvm$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libllvm$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLLVM.dylib $(BUILD_DIST)/libllvm$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	$(LN_S) libLLVM.dylib $(BUILD_DIST)/libllvm$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLLVM-$(LLVM_MAJOR_V).dylib

	# llvm.mk Prep lldb-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/lldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/lldb{,-argdumper,-instr,-server,-vscode} $(BUILD_DIST)/lldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep lldb
	mkdir -p $(BUILD_DIST)/lldb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in lldb{,-argdumper,-instr,-server,-vscode}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$bin $(BUILD_DIST)/lldb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin; \
	done

	# llvm.mk Prep llvm-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bugpoint,dsymutil,llvm-*,llc,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj} $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep llvm
	mkdir -p $(BUILD_DIST)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for file in $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bugpoint,dsymutil,llvm-*,llc,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	done

	# llvm.mk Prep llvm-$(LLVM_MAJOR_V)-runtime
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/lli* $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-runtime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep llvm-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{lib,include}
	for lib in $$(find $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib -name "libLLVM*" -and -name "*.a"); do \
		cp -a $$lib $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib; \
	done
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libRemarks.dylib $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/llvm{,-c} $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include

	# llvm.mk Prep llvm-dev
	mkdir -p $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}
	$(LN_S) ../llvm-$(LLVM_MAJOR_V)/include/llvm $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/llvm
	$(LN_S) ../llvm-$(LLVM_MAJOR_V)/include/llvm-c $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/llvm-c
	$(LN_S) ../llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libLTO.dylib

	# llvm.mk Prep llvm-$(LLVM_MAJOR_V)-linker-tools
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/{libLTO.dylib,LLVMPolly.so} $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	# https://llvm.org/bugs/show_bug.cgi?id=19465
	$(LN_S) ../llvm-$(LLVM_MAJOR_V)/lib/LLVMPolly.so $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/LLVMPolly.dylib

	# llvm.mk Prep clang-tools-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{bin,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{analyze-build,c-index-test,clang-*,diagtool,find-all-symbols,hmaptool,intercept-build,modularize,pp-trace,sancov,scan-build,scan-view} \
			$(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	rm $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang-{$(LLVM_MAJOR_V),cpp,format,tidy}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/libexec $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/lib{ear,scanbuild} $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep clang-tools
	mkdir -p $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for file in $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{analyze-build,c-index-test,clang-*,diagtool,find-all-symbols,hmaptool,intercept-build,modularize,pp-trace,sancov,scan-build,scan-view}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	done

	# llvm.mk Prep swift-$(SWIFT_VERSION)
	mkdir -p $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib,share}}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/swift{,-frontend,c,-api-digester,-api-dump.py,-demangle} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/sil-{func-extractor,llvm-gen,nm,passpipeline-dumper} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/repl_swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift-$(SWIFT_VERSION)
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/swiftc $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swiftc-$(SWIFT_VERSION)

	# llvm.mk Prep swift
	mkdir -p $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/swift}
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/swift $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/swiftc $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swiftc
	cd $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift; \
	for lib in *; do \
		$(LN_S) ../llvm-$(LLVM_MAJOR_V)/lib/swift/$$lib $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/swift/$$lib; \
	done

	# llvm.mk Prep lld-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/lld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{ld.lld,ld64.lld,lld,lld-link,wasm-ld} $(BUILD_DIST)/lld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep lld
	mkdir -p $(BUILD_DIST)/lld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/{ld.lld,ld64.lld,lld,lld-link,wasm-ld} $(BUILD_DIST)/lld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/


	# llvm.mk Sign
	$(call SIGN,clang-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,clangd-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,clang-format-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,clang-tidy-$(LLVM_MAJOR_V),general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call SIGN,debugserver-$(LLVM_MAJOR_V),debugserver.xml)
endif
	$(call SIGN,libclang-cpp$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,liblldb-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,libllvm$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,lldb-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,swift-$(SWIFT_VERSION),general.xml)
	$(call SIGN,llvm-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,llvm-$(LLVM_MAJOR_V)-runtime,general.xml)
	$(call SIGN,llvm-$(LLVM_MAJOR_V)-linker-tools,general.xml)
	$(call SIGN,clang-tools-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,lld-$(LLVM_MAJOR_V),general.xml)
	# repl_swift may need to sign with tfp0.xml

	# llvm.mk Make .debs
	$(call PACK,clang-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang,DEB_LLVM_V)
	$(call PACK,clangd-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clangd,DEB_LLVM_V)
	$(call PACK,clang-format-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang-format,DEB_LLVM_V)
	$(call PACK,clang-tidy-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang-tidy,DEB_LLVM_V)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call PACK,debugserver-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,debugserver,DEB_LLVM_V)
endif
	$(call PACK,libc++-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,libc++-dev,DEB_LLVM_V)
	$(call PACK,libclang-common-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,libclang-cpp$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,libclang1-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,libclang-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,liblld-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,liblld-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,liblldb-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,liblldb-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,libllvm$(LLVM_MAJOR_V),DEB_LLVM_V)			# Provides libllvm-polly
	$(call PACK,lldb-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,lldb,DEB_LLVM_V)
	$(call PACK,swift-$(SWIFT_VERSION),DEB_SWIFT_V)
	$(call PACK,swift,DEB_SWIFT_V)
	$(call PACK,llvm-$(LLVM_MAJOR_V),DEB_LLVM_V)			# Provides dsymutil
	$(call PACK,llvm,DEB_LLVM_V)
	$(call PACK,llvm-dev,DEB_LLVM_V)
	$(call PACK,llvm-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,llvm-$(LLVM_MAJOR_V)-runtime,DEB_LLVM_V)
	$(call PACK,llvm-$(LLVM_MAJOR_V)-linker-tools,DEB_LLVM_V)
	$(call PACK,clang-tools-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang-tools,DEB_LLVM_V)
	$(call PACK,lld-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,lld,DEB_LLVM_V)

	# llvm.mk Build cleanup
	rm -rf $(BUILD_DIST)/{clang*,debugserver*,libc++*,libclang*,liblldb*,liblld*,libllvm*,lldb*,swift*,lld*,llvm*}/

.PHONY: llvm llvm-package
