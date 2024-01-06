ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += llvm
LLVM_MAJOR_V         := 16
LLVM_MINOR_V         := 0
LLVM_PATCH_V         := 0
LLVM_VERSION         := $(LLVM_MAJOR_V).$(LLVM_MINOR_V).$(LLVM_PATCH_V)
LLVM_REVISION        := 2b42c5ce063a374fb22676e27505a22fe411ea8c
LLVM_REPOSITORY      := https://github.com/apple/llvm-project.git
SWIFT_VERSION        := 5.9.2
SWIFT_SUFFIX         := RELEASE
SWIFT_SYNTAX_VERSION := 509.0.2
DEB_SWIFT_V          ?= $(SWIFT_VERSION)~$(SWIFT_SUFFIX)
DEB_LLVM_V           ?= $(LLVM_VERSION)~$(DEB_SWIFT_V)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LLVM_CMAKE_FLAGS :=     -DLLDB_USE_SYSTEM_DEBUGSERVER=ON \
			-DLLVM_CREATE_XCODE_TOOLCHAIN=OFF
else
LLVM_CMAKE_FLAGS :=     -DAPPLE_EMBEDDED=$(MEMO_TARGET) \
			-DLLDB_USE_SYSTEM_DEBUGSERVER=OFF
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LLVM_CMAKE_FLAGS += -DSWIFT_BUILD_SOURCEKIT=ON
else ifneq (,$(findstring iphoneos,$(MEMO_TARGET)))
LLVM_CMAKE_FLAGS += -DSWIFT_BUILD_SOURCEKIT=ON
else
LLVM_CMAKE_FLAGS += -DSWIFT_BUILD_SOURCEKIT=OFF
endif
llvm-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/apple/llvm-project/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz)
	$(call GITHUB_ARCHIVE,apple,swift,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-swift)
	$(call GITHUB_ARCHIVE,apple,cmark,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-cmark)
	$(call GITHUB_ARCHIVE,apple,swift-syntax,$(SWIFT_SYNTAX_VERSION),$(SWIFT_SYNTAX_VERSION),swift-syntax)
	$(call EXTRACT_TAR,swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,llvm-project-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm)
	$(call EXTRACT_TAR,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/swift)
	$(call EXTRACT_TAR,swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-cmark-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/cmark)
	$(call EXTRACT_TAR,swift-syntax-$(SWIFT_SYNTAX_VERSION).tar.gz,swift-syntax-$(SWIFT_SYNTAX_VERSION),llvm/swift-syntax)
	$(call DO_PATCH,llvm,llvm,-p1)
	$(call DO_PATCH,swift,llvm/swift,-p1)
	sed -i "s|VERBATIM COMMAND mig |VERBATIM COMMAND mig -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include |" $(BUILD_WORK)/llvm/lldb/tools/debugserver/source/CMakeLists.txt
	sed -i 's|#define HAS_FLOAT128 1|#define HAS_FLOAT128 0|g' $(BUILD_WORK)/llvm/flang/include/flang/Runtime/float128.h
	mkdir -p $(BUILD_WORK)/llvm/build
	mkdir -p $(BUILD_WORK)/../../native/llvm/lib/swift
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's|isysroot $${CMAKE_OSX_SYSROOT}|isysroot $${CMAKE_FIND_ROOT_PATH}|' $(BUILD_WORK)/llvm/lldb/tools/debugserver/source/CMakeLists.txt
endif
	# maybe we can do something about it instead of disabling dsc code, see dyld source code
	sed -i '/define SDK_HAS_NEW_DYLD_INTROSPECTION_SPIS/d' $(BUILD_WORK)/llvm/lldb/source/Host/macosx/objcxx/HostInfoMacOSX.mm
	sed -i 's/if TARGET_OS_IPHONE/if 0/g' $(BUILD_WORK)/llvm/lldb/source/Plugins/ObjectFile/Mach-O/ObjectFileMachO.cpp
	sed -i 's/# Include CMake modules/set(SWIFT_BUILD_SWIFT_SYNTAX TRUE)/g' $(BUILD_WORK)/llvm/swift/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/llvm/.build_complete),)
llvm:
	@echo "Using previously built llvm."
else
llvm: llvm-setup libffi libedit ncurses xz xar
ifeq ($(wildcard $(BUILD_WORK)/../../native/llvm/.build_complete),)
	mkdir -p $(BUILD_WORK)/../../native/llvm && cd $(BUILD_WORK)/../../native/llvm && unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=cc \
		-DCMAKE_CXX_COMPILER=c++ \
		-DCMAKE_C_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)" \
		-DSWIFT_INCLUDE_TESTS=OFF \
		-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
		-DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
		-DLLVM_ENABLE_PROJECTS="clang;lldb" \
		-DLLVM_ENABLE_RUNTIMES="libcxxabi;libcxx" \
		-DLLVM_EXTERNAL_PROJECTS="cmark;swift" \
		-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR="$(BUILD_WORK)/llvm/swift" \
		-DLLVM_EXTERNAL_CMARK_SOURCE_DIR="$(BUILD_WORK)/llvm/cmark" \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$(BUILD_WORK)/llvm/swift-syntax" \
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
		SWIFT_VARIANT=WATCHOS \
		;; \
	esac; \
	cd $(BUILD_WORK)/llvm/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		$(LLVM_CMAKE_FLAGS) \
		-G Ninja \
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
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_BUILD_TYPE=Release;-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="$(CFLAGS_FOR_BUILD)";-DCMAKE_CXX_FLAGS="$(CXXFLAGS_FOR_BUILD)";-DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS_FOR_BUILD)";-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$(BUILD_WORK)/llvm/swift-syntax";-DCMAKE_Swift_COMPILER="$(shell xcrun --find swiftc)";-DSWIFT_BUILD_SWIFT_SYNTAX=TRUE' \
		-DRUNTIMES_CMAKE_ARGS='-DCMAKE_BUILD_TYPE=$(MEMO_CMAKE_BUILD_TYPE);-DCMAKE_CROSSCOMPILING=true;-DCMAKE_SYSTEM_NAME=Darwin;-DCMAKE_SYSTEM_PROCESSOR=$(shell echo $(GNU_HOST_TRIPLE) | cut -f1 -d-);-DCMAKE_C_FLAGS=$(OPTIMIZATION_FLAGS) $(PLATFORM_VERSION_MIN) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(TARGET_SYSROOT)/usr/include;-DCMAKE_CXX_FLAGS=$(OPTIMIZATION_FLAGS) $(PLATFORM_VERSION_MIN) -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -isystem $(TARGET_SYSROOT)/usr/include;-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)";-DPKG_CONFIG_EXECUTABLE="$(BUILD_TOOLS)/cross-pkg-config";-DCMAKE_INSTALL_NAME_TOOL="$(I_N_T)";-DCMAKE_INSTALL_PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)";-DCMAKE_INSTALL_NAME_DIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib";-DCMAKE_INSTALL_RPATH="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)";-DCMAKE_INSTALL_SYSCONFDIR="$(MEMO_PREFIX)/etc";-DCMAKE_OSX_SYSROOT="../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../../$(TARGET_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES=$(MEMO_ARCH)' \
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
		-DLLVM_TARGETS_TO_BUILD="all" \
		-DLLVM_ENABLE_PROJECTS="bolt;clang;flang;lldb;clang-tools-extra;lld;polly;pstl;mlir;libclc;openmp" \
		-DLLVM_ENABLE_RUNTIMES="libcxxabi;libcxx" \
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
		-DCMAKE_CXX_STANDARD_LIBRARIES="-lcompression" \
		-DLLDB_BUILD_FRAMEWORK=OFF \
		-DLLDB_ENABLE_LUA=OFF \
		-DLLDB_ENABLE_PYTHON=OFF \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_IOS="$(IPHONEOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX="$(MACOSX_DEPLYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_WATCHOS="$(WATCHOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_TVOS="$(APPLETVOS_DEPLYMENT_TARGET)" \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=TRUE \
		-DSWIFT_STDLIB_SUPPORT_BACK_DEPLOYMENT=TRUE \
		-DSWIFT_BUILD_SWIFT_SYNTAX=TRUE \
		-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$(BUILD_WORK)/llvm/swift-syntax" \
		-DCMAKE_Swift_COMPILER="$(shell xcrun --find swiftc)" \
		-DCMAKE_Swift_FLAGS="-O --target=$(LLVM_TARGET) -sdk $(TARGET_SYSROOT) -I$(BUILD_WORK)/llvm/build-compiler-rt/memo-include" \
		-DPACKAGE_VENDOR="Procursus" \
		-DBUG_REPORT_URL="https://github.com/ProcursusTeam/Procursus/issues" \
		-DFFI_INCLUDE_PATH="$(BUILD_WORK)/llvm/build-compiler-rt/memo-include" \
		-DFFI_LIBRARY_PATH="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libffi.dylib" \
		-DCURSES_CURSES_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
		-DCURSES_FORM_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libformw.dylib" \
		-DCURSES_NCURSES_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
		-DLIBLZMA_LIBRARY_RELEASE="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/liblzma.dylib" \
		-Dzstd_INCLUDE_DIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		-Dzstd_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzstd.dylib" \
		-Dzstd_STATIC_LIBRARY="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzstd.a" \
		-DPANEL_LIBRARIES="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpanelw.dylib" \
		-DTERMINFO_LIB="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libncursesw.dylib" \
		../llvm
	mkdir -p $(BUILD_WORK)/llvm/build/share/swift # ¯\_(ツ)_/¯
	sed -i 's|-arch\\ $(shell uname -m)\\ -mmacosx-version-min=$(shell sw_vers -productVersion)\\ -isysroot\\ $(MACOSX_SYSROOT)||g' $(BUILD_WORK)/llvm//build/build.ninja
	# if something wants arm64e, do not insert -arch arm64
	sed -i -E -e 's|FLAGS = $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) (.*) -arch arm64e (.*)|FLAGS = $(OPTIMIZATION_FLAGS) -arch arm64e \1 \2|g' $(BUILD_WORK)/llvm//build/build.ninja
	# same goes for x86_64 and arm64
	sed -i -E -e 's|FLAGS = $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) (.*) -arch x86_64 (.*)|FLAGS = $(OPTIMIZATION_FLAGS) -arch x86_64 \1 \2|g' $(BUILD_WORK)/llvm//build/build.ninja
	sed -i -E -e 's|FLAGS = $(OPTIMIZATION_FLAGS) -arch $(MEMO_ARCH) (.*) -arch arm64 (.*)|FLAGS = $(OPTIMIZATION_FLAGS) -arch arm64 \1 \2|g' $(BUILD_WORK)/llvm//build/build.ninja
	DESTDIR="$(BUILD_STAGE)/llvm" ninja -C $(BUILD_WORK)/llvm/build
	mkdir -p $(BUILD_WORK)/llvm/build/lib/swift{,_static}/$(PLATFORM)/Cxx{,Stdlib}.swiftmodule
	DESTDIR="$(BUILD_STAGE)/llvm" ninja -C $(BUILD_WORK)/llvm/build install
	$(INSTALL) -Dm755 $(BUILD_WORK)/llvm/build/bin/{obj2yaml,yaml2obj} $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/
	touch $(BUILD_WORK)/llvm/build/.build_complete
endif

ifeq ($(wildcard $(BUILD_WORK)/llvm/build-compiler-rt/.build_complete),)
	# Now we compile compiler-rt.
	# We do it seperately because CMake will set the correct flags for cross compiling for us,
	# which we will conflict with.
	# we need to set the archs for each OS we want the builtins to target because
	# otherwise it will compile for bogus targets like armv7 tvOS as well as missing
	# some targets like arm64e ios
	# In Xcode the watchos debugging tools like asan supports armv7 armv7s arm64_32 arm64 arm64e but
	# the builtins supports armv7k arm64_32 arm64 arm64e which is very weird but we attempt to follow
	# regardless
	# FIXME: Add visionOS when we update LLVM again (not supported in this version)
	mkdir -p $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/mach
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/time.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/unistd.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/mach/task.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/spawn.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/spawn.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/mach/mach_host.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/thread_act.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/mach/thread_act.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/message.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/mach/message.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/ucontext.h
	sed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/signal.h
	sed -i 's/__API_UNAVAILABLE(.*)//g' $(BUILD_WORK)/llvm/build-compiler-rt/memo-include/*.h
	mkdir -p $(BUILD_WORK)/llvm/build-compiler-rt && cd $(BUILD_WORK)/llvm/build-compiler-rt && unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && cmake . \
		-G 'Unix Makefiles' \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER="cc" \
		-DCMAKE_CXX_COMPILER="c++" \
		-DCMAKE_C_FLAGS="-isystem $(BUILD_WORK)/llvm/build-compiler-rt/memo-include -Wl,-ld_classic" \
		-DCMAKE_CXX_FLAGS="-isystem $(BUILD_WORK)/llvm/build-compiler-rt/memo-include -Wl,-ld_classic" \
		-DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DCOMPILER_RT_ENABLE_IOS=ON \
		-DCOMPILER_RT_ENABLE_TVOS=ON \
		-DCOMPILER_RT_ENABLE_WATCHOS=ON \
		-DCOMPILER_RT_ENABLE_MACCATALYST=ON \
		-DDARWIN_osx_ARCHS="x86_64;x86_64h;arm64;arm64e" \
		-DDARWIN_ios_ARCHS="armv7;armv7s;arm64;arm64e" \
		-DDARWIN_iossim_ARCHS="x86_64;arm64" \
		-DDARWIN_tvos_ARCHS="arm64;arm64e" \
		-DDARWIN_tvossim_ARCHS="x86_64;arm64" \
		-DDARWIN_watchos_ARCHS="armv7;armv7s;arm64_32;arm64;arm64e" \
		-DDARWIN_watchossim_ARCHS="x86_64;arm64" \
		-DDARWIN_osx_BUILTIN_ARCHS="x86_64;x86_64h;arm64;arm64e" \
		-DDARWIN_ios_BUILTIN_ARCHS="armv7;armv7s;arm64;arm64e" \
		-DDARWIN_iossim_BUILTIN_ARCHS="x86_64;arm64" \
		-DDARWIN_tvos_BUILTIN_ARCHS="arm64;arm64e" \
		-DDARWIN_tvossim_BUILTIN_ARCHS="x86_64;arm64" \
		-DDARWIN_watchos_BUILTIN_ARCHS="armv7k;arm64_32;arm64;arm64e" \
		-DDARWIN_watchossim_BUILTIN_ARCHS="x86_64;arm64" \
		-DDARWIN_osx_BUILTIN_ALL_POSSIBLE_ARCHS="x86_64;x86_64h;arm64;arm64e" \
		-DDARWIN_ios_BUILTIN_ALL_POSSIBLE_ARCHS="armv7;armv7s;arm64;arm64e" \
		-DDARWIN_iossim_BUILTIN_ALL_POSSIBLE_ARCHS="x86_64;arm64" \
		-DDARWIN_tvos_BUILTIN_ALL_POSSIBLE_ARCHS="arm64;arm64e" \
		-DDARWIN_tvossim_BUILTIN_ALL_POSSIBLE_ARCHS="x86_64;arm64" \
		-DDARWIN_watchos_BUILTIN_ALL_POSSIBLE_ARCHS="armv7k;arm64_32;arm64;arm64e" \
		-DDARWIN_watchossim_BUILTIN_ALL_POSSIBLE_ARCHS="x86_64;arm64" \
		$(BUILD_WORK)/llvm/llvm
	+unset MACOSX_DEPLOYMENT_TARGET IPHONEOS_DEPLOYMENT_TARGET APPLETVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET BRIDGEOS_DEPLOYMENT_TARGET && \
	$(MAKE) -C $(BUILD_WORK)/llvm/build-compiler-rt install-compiler-rt \
		DESTDIR="$(BUILD_STAGE)/llvm"
	touch $(BUILD_WORK)/llvm/build-compiler-rt/.build_complete
endif
	# Let's build wrappers now
	mkdir -p $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	for tool in bbc clang clang++ clang-cpp clang-cl flang-new llc swift swiftc; do \
		$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_MISC)/llvm/wrapper.c -o $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$tool-$(LLVM_MAJOR_V) \
			-DTOOL=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/$$tool\" -DDEFAULT_SYSROOT=\"$(ON_DEVICE_SDK_PATH)\" \
			-DEXTRA_CPATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include\" -DEXTRA_LIBRARY_PATH=\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib\"; \
	done

ifeq ($(MEMO_ARCH), x86_64)
	-cp -a $(BUILD_STAGE)/llvm/usr/local/lib/libbolt*.a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib # ...
endif

	# Note the mkdir above. These are just blank folders.
	rm -rf $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/lib/swift{,_static}/$(PLATFORM)/Cxx{,Stdlib}.swiftmodule
	$(call AFTER_BUILD,,,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib)
ifneq ($(MEMO_PREFIX),)
	-$(I_N_T) -change @rpath/libc++.1.dylib /usr/lib/libc++.1.dylib $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/bin/flang-new
	-$(I_N_T) -add_rpath $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/lib/sourcekitd.framework $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/bin/sourcekitd-test
	-$(I_N_T) -add_rpath $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/lib/sourcekitd.framework $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-16/bin/sourcekitd-repl
endif
endif

llvm-package: llvm-stage
	# llvm.mk Package Structure
	rm -rf $(BUILD_DIST)/{bolt*,clang*,debugserver*,flang*,libbolt*,libc++*,libclang*,libflang*,liblldb*,liblld*,libmlir*,libllvm*,lldb*,mlir*,swift*,lld*,llvm*}/

	# llvm.mk Prep bolt-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/bolt-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{perf2bolt,llvm-bolt{,-heatmap,diff},merge-fdata} $(BUILD_DIST)/bolt-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	for bin in llvm-bolt llvm-bolt-heatmap llvm-boltdiff perf2bolt merge-fdata; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$bin $(BUILD_DIST)/bolt-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin-$(LLVM_MAJOR_V); \
	done

	# llvm.mk Prep llvm-bolt
	mkdir -p $(BUILD_DIST)/llvm-bolt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in llvm-bolt llvm-bolt-heatmap llvm-boltdiff perf2bolt; do \
		$(LN_S) $$bin-$(LLVM_MAJOR_V) $(BUILD_DIST)/llvm-bolt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/$$bin; \
	done

ifeq ($(MEMO_ARCH),x86_64)
	# llvm.mk Prep libbolt-16-dev
	mkdir -p $(BUILD_DIST)/libbolt-16-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libbolt_*.a $(BUILD_DIST)/libbolt-16-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
endif

	# llvm.mk Prep clang-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib/cmake,share/clang}}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang{,-$(LLVM_MAJOR_V),++,-cpp} $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang/* $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang
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
	mkdir -p $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V),}/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{,git-}clang-format $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-format $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-format-$(LLVM_MAJOR_V)
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/git-clang-format $(BUILD_DIST)/clang-format-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/git-clang-format-$(LLVM_MAJOR_V)

	# llvm.mk Prep clang-format
	mkdir -p $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) clang-format-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-format
	$(LN_S) git-clang-format-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-format/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/git-clang-format

	# llvm.mk Prep clang-tidy-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V),}/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{run-,}clang-tidy $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-tidy $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-tidy-$(LLVM_MAJOR_V)
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/run-clang-tidy $(BUILD_DIST)/clang-tidy-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/run-clang-tidy-$(LLVM_MAJOR_V)

	# llvm.mk Prep clang-tidy
	mkdir -p $(BUILD_DIST)/clang-tidy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) clang-tidy-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-tidy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-tidy

	# llvm.mk Prep clangd-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V),}/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clangd $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/clangd $(BUILD_DIST)/clangd-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clangd-$(LLVM_MAJOR_V)

	# llvm.mk Prep clangd
	mkdir -p $(BUILD_DIST)/clangd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) clangd-$(LLVM_MAJOR_V) $(BUILD_DIST)/clangd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clangd

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	# llvm.mk Prep debugserver-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver{,-nonui} $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver-$(LLVM_MAJOR_V)

	# llvm.mk Prep debugserver
	mkdir -p $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver-nonui $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver-nonui
endif

	# llvm.mk Prep flang-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/flang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V),}/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bbc,f18-parse-demo,fir-opt,flang-new,flang-to-external-fc,tco} $(BUILD_DIST)/flang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{bbc,flang-new}-16 $(BUILD_DIST)/flang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in f18-parse-demo fir-opt flang-to-external-fc tco; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$bin $(BUILD_DIST)/flang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin-$(LLVM_MAJOR_V); \
	done

	# llvm.mk Prep flang
	mkdir -p $(BUILD_DIST)/flang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for tool in bbc f18-parse-demo fir-opt flang-new flang-to-external-fc; do \
		$(LN_S) $$tool-$(LLVM_MAJOR_V) $(BUILD_DIST)/flang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$tool; \
	done

	# llvm.mk Prep libflang-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libflang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{lib,include}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/flang $(BUILD_DIST)/libflang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/lib{Fortran,FIR,flang}*.a $(BUILD_DIST)/libflang-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include

	# llvm.mk Prep libc++-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/c++ $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/*pstl* $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include

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
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V)/{bin,share},bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bugpoint,darwin-debug,dsymutil,llvm-{opt-report,lipo,debuginfod,profgen,cxxdump,cvtres,strings,windres,sim,install-name-tool,remark-size-diff,config,lto2,cfi-verify,cov,link,symbolizer,objdump,debuginfod-find,mca,rc,addr2line,jitlink,xray,otool,rtdyld,lto,c-test,dwp,reduce,mc,exegesis,readelf,as,nm,lib,undname,ml,ar,dis,size,dlltool,readobj,libtool-darwin,cxxfilt,pdbutil,ifs,bat-dump,dwarfutil,tblgen,dwarfdump,cas,cat,profdata,objcopy,extract,split,bcanalyzer,remarkutil,stress,diff,tli-checker,tapi-diff,modextract,gsymutil,strip,mt,ranlib,bitcode-strip,cxxmap},llc,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj} $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
ifeq ($(shell grep -E 'iphoneos|darwin' <<< $(MEMO_TARGET) && echo 1),1)
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/complete-test $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
endif
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/opt-viewer $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/llc-$(LLVM_MAJOR_V) $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/llc-$(LLVM_MAJOR_V)
	for file in $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bugpoint,darwin-debug,dsymutil,llvm-*,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename "$$file")-$(LLVM_MAJOR_V); \
	done

	# llvm.mk Prep llvm
	mkdir -p $(BUILD_DIST)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for file in $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{bugpoint,darwin-debug,dsymutil,llvm-*,llc,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj}; do \
		$(LN_S) $$(basename "$$file")-$(LLVM_MAJOR_V) $(BUILD_DIST)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename "$$file"); \
	done
ifeq ($(shell grep -E 'iphoneos|darwin' <<< $(MEMO_TARGET) && echo 1),1)
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/complete-test $(BUILD_DIST)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
endif

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
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/include/llvm $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/llvm
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/include/llvm-c $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/llvm-c
	$(LN_S) llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib $(BUILD_DIST)/llvm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libLTO.dylib

	# llvm.mk Prep llvm-$(LLVM_MAJOR_V)-linker-tools
	mkdir -p $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/{libLTO.dylib,LLVMPolly.so} $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	# https://llvm.org/bugs/show_bug.cgi?id=19465
	$(LN_S) llvm-$(LLVM_MAJOR_V)/lib/LLVMPolly.so $(BUILD_DIST)/llvm-$(LLVM_MAJOR_V)-linker-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/LLVMPolly.dylib

	# llvm.mk Prep libmlir-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/{objects-Release,{libMLIR,libmlir_*}.dylib} $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep mlir-$(LLVM_MAJOR_V)-tools
	mkdir -p $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{mlir-*,tblgen-lsp-server} $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	for file in $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{mlir-*,tblgen-lsp-server}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/libmlir-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename "$$file")-$(LLVM_MAJOR_V); \
	done

	# llvm.mk Prep clang-tools-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/llvm-$(LLVM_MAJOR_V)/{bin,lib,share/man/man1},bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{analyze-build,c-index-test,clang-*,diagtool,find-all-symbols,hmaptool,intercept-build,modularize,pp-trace,sancov,scan-build,scan-build-py,scan-view,set-xcode-analyzer} \
			$(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	rm $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang-{$(LLVM_MAJOR_V),cpp,format,tidy}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/libexec $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/lib{ear,scanbuild} $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/scan-build.1 $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/scan-build.1
	$(MEMO_MANPAGE_COMPCMD) $(MEMO_MANPAGE_COMPFLGS) $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/scan-build.1
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/scan-view $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share
	for file in $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{analyze-build,c-index-test,clang-*,diagtool,find-all-symbols,hmaptool,intercept-build,modularize,pp-trace,sancov,scan-build,scan-build-py,scan-view}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename $$file)-$(LLVM_MAJOR_V); \
	done
	rm $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cl-$(LLVM_MAJOR_V)
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cl-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# llvm.mk Prep clang-tools
	mkdir -p $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	for file in $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{analyze-build,c-index-test,clang-*,diagtool,find-all-symbols,hmaptool,intercept-build,modularize,pp-trace,sancov,scan-build,scan-build-py,scan-view,set-xcode-analyzer}; do \
		$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	done
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/scan-build.1$(MEMO_MANPAGE_COMPRESSION) $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/scan-build.1$(MEMO_MANPAGE_COMPRESSION)

	# llvm.mk Prep swift-$(SWIFT_VERSION)
	mkdir -p $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib,share/man/man{1,3}},share/man/man1}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/{swift,cmark-gfm}.1 $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man3/cmark-gfm.3 $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man3
	$(MEMO_MANPAGE_COMPCMD) $(MEMO_MANPAGE_COMPFLGS) $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/swift.1
	$(MEMO_MANPAGE_COMPCMD) $(MEMO_MANPAGE_COMPFLGS) $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/cmark-gfm.1
	$(MEMO_MANPAGE_COMPCMD) $(MEMO_MANPAGE_COMPFLGS) $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/man/man3/cmark-gfm.3
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/swift{,-frontend,c,-api-digester,-api-dump.py,-demangle} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/sil-{func-extractor,llvm-gen,nm,opt,passpipeline-dumper} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{repl_swift,sdk-module-lists} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift{c,}-$(SWIFT_VERSION) $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	# Don't link cmark-gfm.1$(MEMO_MANPAGE_SUFFIX), as it conflicts with the cmark package
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/share/man/man1/swift.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/swift-$(SWIFT_VERSION).1$(MEMO_MANPAGE_SUFFIX)
ifeq ($(shell grep -qE 'iphoneos|darwin' <<< $(MEMO_TARGET) && echo 1),1)
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/sourcekitd.framework $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{sourcekitd-repl,sourcekitd-test} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/sourcekitd-repl $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sourcekitd-repl-$(SWIFT_VERSION)
	$(LN_S) ../lib/llvm-$(LLVM_MAJOR_V)/bin/sourcekitd-test $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sourcekitd-test-$(SWIFT_VERSION)
endif

	# llvm.mk Prep swift
	mkdir -p $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/swift,share/{man/man1,emacs}}
	$(LN_S) swift-$(SWIFT_VERSION) $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift
	$(LN_S) swiftc-$(SWIFT_VERSION) $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swiftc
	cd $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift; \
	for lib in *; do \
		$(LN_S) ../llvm-$(LLVM_MAJOR_V)/lib/swift/$$lib $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/swift/$$lib; \
	done
	$(LN_S) swift-$(SWIFT_VERSION).1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/swift.1$(MEMO_MANPAGE_SUFFIX)
ifeq ($(shell grep -qE 'iphoneos|darwin' <<< $(MEMO_TARGET) && echo 1),1)
	$(LN_S) sourcekitd-repl-$(SWIFT_VERSION) $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sourcekitd-repl
	$(LN_S) sourcekitd-test-$(SWIFT_VERSION) $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sourcekitd-test
endif

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
	$(call SIGN,bolt-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,libmlir-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,mlir-$(LLVM_MAJOR_V)-tools,general.xml)
	$(call SIGN,flang-$(LLVM_MAJOR_V),general.xml)
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
	$(call PACK,llvm-bolt,DEB_LLVM_V)
	$(call PACK,bolt-$(LLVM_MAJOR_V),DEB_LLVM_V)
ifeq ($(MEMO_ARCH),x86_64)
	$(call PACK,libbolt-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
endif
	$(call PACK,mlir-$(LLVM_MAJOR_V)-tools,DEB_LLVM_V)
	$(call PACK,libmlir-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,flang-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,libflang-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,flang,DEB_LLVM_V)

	# llvm.mk Build cleanup
	rm -rf $(BUILD_DIST)/{bolt*,clang*,debugserver*,flang*,libbolt*,libc++*,libclang*,libflang*,liblldb*,liblld*,libmlir*,libllvm*,lldb*,mlir*,swift*,lld*,llvm*}/

.PHONY: llvm llvm-package
