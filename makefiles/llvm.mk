ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#### Next time you mess with this, add in compiler-rt stuff

SUBPROJECTS   += llvm
LLVM_VERSION  := 11.1.0
LLVM_MAJOR_V  := 11
SWIFT_VERSION := 5.4.1
SWIFT_SUFFIX  := RELEASE
DEB_SWIFT_V   ?= $(SWIFT_VERSION)~$(SWIFT_SUFFIX)
DEB_LLVM_V    ?= $(LLVM_VERSION)~$(DEB_SWIFT_V)

llvm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/apple/llvm-project/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz
	$(call GITHUB_ARCHIVE,apple,swift,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-swift)
	$(call GITHUB_ARCHIVE,apple,cmark,$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),swift-cmark)
	$(call EXTRACT_TAR,swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,llvm-project-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm)
	$(call EXTRACT_TAR,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/swift)
	$(call EXTRACT_TAR,swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-cmark-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/cmark)
	$(call DO_PATCH,llvm,llvm,-p1)
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/llvm/clang/lib/Frontend/InitHeaderSearch.cpp \
		$(BUILD_WORK)/llvm/clang/lib/Driver/ToolChains/Darwin.cpp
	$(call DO_PATCH,swift,llvm/swift,-p1)
	mkdir -p $(BUILD_WORK)/llvm/build
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(SED) -i 's|isysroot $${CMAKE_OSX_SYSROOT}|isysroot $${CMAKE_FIND_ROOT_PATH}|' $(BUILD_WORK)/llvm/lldb/tools/debugserver/source/CMakeLists.txt
endif

ifneq ($(wildcard $(BUILD_WORK)/llvm/.build_complete),)
llvm:
	@echo "Using previously built llvm."
else
llvm: llvm-setup libffi libedit ncurses xz xar
#	Temporary SED until swift can build on their own apple silicon (cmon apple)
	$(SED) -i -e 's/aarch64|ARM64/aarch64|ARM64|arm64/' -e 's/SWIFT_HOST_VARIANT_ARCH_default "aarch64"/SWIFT_HOST_VARIANT_ARCH_default "arm64"/' $(BUILD_WORK)/llvm/swift/CMakeLists.txt

ifeq ($(wildcard $(BUILD_WORK)/../../native/llvm/.*),)
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
	+$(MAKE) -C $(BUILD_WORK)/../../native/llvm swift-components lldb-tblgen
endif

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
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V) \
		-DLLVM_ENABLE_FFI=ON \
		-DLLVM_ENABLE_RTTI=ON \
		-DLLVM_ENABLE_EH=ON \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="$(BUILD_CFLAGS)";-DCMAKE_CXX_FLAGS="$(BUILD_CXXFLAGS)";-DCMAKE_EXE_LINKER_FLAGS="$(BUILD_LDFLAGS)"' \
		-DCLANG_VERSION=$(LLVM_VERSION) \
		-DLLVM_ENABLE_LTO=THIN \
		-DLLVM_BUILD_LLVM_DYLIB=ON \
		-DLLVM_LINK_LLVM_DYLIB=ON \
		-DCLANG_LINK_CLANG_DYLIB=ON \
		-DLIBCXX_OVERRIDE_DARWIN_INSTALL=ON \
		-DLLVM_VERSION_SUFFIX="" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_TARGET) \
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
		-DSWIFT_HOST_VARIANT="$(PLATFORM)" \
		-DSWIFT_HOST_VARIANT_ARCH="$(MEMO_ARCH)" \
		-DCFLAGS_SDK=$${SWIFT_VARIANT} \
		-DSWIFT_HOST_VARIANT_SDK=$${SWIFT_VARIANT} \
		-DSWIFT_ENABLE_IOS32=OFF \
		-DSWIFT_INCLUDE_TESTS=OFF \
		-DSWIFT_TOOLS_ENABLE_LTO=THIN \
		-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
		-DSWIFT_NATIVE_SWIFT_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DSWIFT_NATIVE_CLANG_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DSWIFT_NATIVE_LLVM_TOOLS_PATH="$(BUILD_WORK)/../../native/llvm/bin" \
		-DLLVM_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/llvm-tblgen" \
		-DLLVM_TABLEGEN_EXE="$(BUILD_WORK)/../../native/llvm/bin/llvm-tblgen" \
		-DCLANG_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/clang-tblgen" \
		-DCLANG_TABLEGEN_EXE="$(BUILD_WORK)/../../native/llvm/bin/clang-tblgen" \
		-DLLDB_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" \
		-DLLDB_TABLEGEN_EXE="$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_IOS="$(IPHONEOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX="$(MACOSX_DEPLYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_WATCHOS="$(WATCHOS_DEPLOYMENT_TARGET)" \
		-DSWIFT_DARWIN_DEPLOYMENT_VERSION_TVOS="$(APPLETVOS_DEPLYMENT_TARGET)" \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=FALSE \
		../llvm
	+$(MAKE) -C $(BUILD_WORK)/llvm/build install \
		DESTDIR="$(BUILD_STAGE)/llvm"
	$(INSTALL) -Dm755 $(BUILD_WORK)/llvm/build/bin/{obj2yaml,yaml2obj} $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/
	touch $(BUILD_WORK)/llvm/.build_complete
endif

llvm-package: llvm-stage
	# llvm.mk Package Structure
	rm -rf $(BUILD_DIST)/{clang*,debugserver*,libc++*-dev,libclang-common-*-dev,libclang-cpp*,liblldb-*,libllvm*,liblto*,lldb*,dsymutil*,swift*,lld*,llvm-utils*}/

	# llvm.mk Prep clang-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib/cmake,share/clang}}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/clang{,-$(LLVM_MAJOR_V),++,-cpp} $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang/bash-autocomplete.sh $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/clang
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake/clang $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-$(LLVM_MAJOR_V) $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-$(LLVM_MAJOR_V)
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-cpp $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cpp-$(LLVM_MAJOR_V)
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang++ $(BUILD_DIST)/clang-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang++-$(LLVM_MAJOR_V)

	# llvm.mk Prep clang
	mkdir -p $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang++ $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang++
	ln -s clang $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cc
	ln -s clang++ $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/c++
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/clang-cpp $(BUILD_DIST)/clang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/clang-cpp

	# llvm.mk Prep debugserver-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver-$(LLVM_MAJOR_V)

	# llvm.mk Prep debugserver
	mkdir -p $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/debugserver $(BUILD_DIST)/debugserver/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/debugserver

	# llvm.mk Prep libc++-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/{include,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/c++ $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libc++{,.1}.dylib $(BUILD_DIST)/libc++-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep libc++-dev
	mkdir -p $(BUILD_DIST)/libc++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/include/c++ $(BUILD_DIST)/libc++-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# llvm.mk Prep libllvm-polly$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libllvm-polly$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/include/polly $(BUILD_DIST)/libllvm-polly$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/{libPollyISL.a,LLVMPolly.so,libPollyPPCG.a,libPolly.a} $(BUILD_DIST)/libllvm-polly$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/cmake/polly $(BUILD_DIST)/libllvm-polly$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# llvm.mk Prep libclang-common-$(LLVM_MAJOR_V)-dev
	mkdir -p $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{,llvm-$(LLVM_MAJOR_V)/lib/}clang
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/clang/$(LLVM_VERSION) $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/clang
	ln -s ../llvm-$(LLVM_MAJOR_V)/lib/clang/$(LLVM_VERSION) $(BUILD_DIST)/libclang-common-$(LLVM_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/clang

	# llvm.mk Prep libclang-cpp$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libclang-cpp$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libclang-cpp*.dylib $(BUILD_DIST)/libclang-cpp$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep liblldb-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/liblldb.$(LLVM_VERSION).dylib $(BUILD_DIST)/liblldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep libllvm$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/libllvm$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLLVM.dylib $(BUILD_DIST)/libllvm$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep liblto$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/liblto$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib $(BUILD_DIST)/liblto$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib

	# llvm.mk Prep liblto
	mkdir -p $(BUILD_DIST)/liblto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	ln -s ./llvm-$(LLVM_MAJOR_V)/lib/libLTO.dylib $(BUILD_DIST)/liblto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libLTO.dylib

	# llvm.mk Prep lldb-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/lldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/lldb{,-argdumper,-instr,-server} $(BUILD_DIST)/lldb-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep lldb
	mkdir -p $(BUILD_DIST)/lldb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for bin in lldb{,-argdumper,-instr,-server}; do \
		ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$bin $(BUILD_DIST)/lldb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin; \
	done

	# llvm.mk Prep llvm-utils-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/llvm-utils-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{llvm-*,llc,lli,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj} $(BUILD_DIST)/llvm-utils-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep llvm-utils
	mkdir -p $(BUILD_DIST)/llvm-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for file in $(BUILD_DIST)/llvm-utils-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{llvm-*,llc,lli,obj2yaml,opt,sanstats,verify-uselistorder,yaml2obj}; do \
		ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/llvm-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	done

	# llvm.mk Prep clang-tools-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{c-index-test,clang-*,clangd,sancov,scan-build,scan-view} \
			$(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	rm $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{clang-$(LLVM_MAJOR_V),clang-cpp}

	# llvm.mk Prep clang-tools
	mkdir -p $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	for file in $(BUILD_DIST)/clang-tools-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{c-index-test,clang-*,clangd,sancov,scan-build,scan-view}; do \
		ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/$$(basename "$$file") $(BUILD_DIST)/clang-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/; \
	done

	# llvm.mk Prep dsymutil-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/dsymutil-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/bin}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/dsymutil $(BUILD_DIST)/dsymutil-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/dsymutil $(BUILD_DIST)/dsymutil-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dsymutil-$(LLVM_MAJOR_V)

	# llvm.mk Prep dsymutil
	mkdir -p $(BUILD_DIST)/dsymutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/dsymutil $(BUILD_DIST)/dsymutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dsymutil

	# llvm.mk Prep swift-$(SWIFT_VERSION)
	mkdir -p $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/llvm-$(LLVM_MAJOR_V)/{bin,lib,share}}
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/share
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/swift{,-frontend,c,-api-digester,-api-dump.py,-demangle,-syntax*} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/sil-{func-extractor,llvm-gen,nm,passpipeline-dumper} $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/repl_swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/swift $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift-$(SWIFT_VERSION)
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/swiftc $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swiftc-$(SWIFT_VERSION)

	# llvm.mk Prep swift
	mkdir -p $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib/swift}
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/swift $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swift
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/swiftc $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swiftc
	cd $(BUILD_DIST)/swift-$(SWIFT_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/lib/swift; \
	for lib in *; do \
		ln -s ../llvm-$(LLVM_MAJOR_V)/lib/swift/$$lib $(BUILD_DIST)/swift/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/swift/$$lib; \
	done

	# llvm.mk Prep lld-$(LLVM_MAJOR_V)
	mkdir -p $(BUILD_DIST)/lld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/llvm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin/{ld.lld,ld64.lld,lld,lld-link,wasm-ld} $(BUILD_DIST)/lld-$(LLVM_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/llvm-$(LLVM_MAJOR_V)/bin

	# llvm.mk Prep lld
	mkdir -p $(BUILD_DIST)/lld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	ln -s ../lib/llvm-$(LLVM_MAJOR_V)/bin/{ld.lld,ld64.lld,lld,lld-link,wasm-ld} $(BUILD_DIST)/lld/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/


	# llvm.mk Sign
	$(call SIGN,clang-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,debugserver-$(LLVM_MAJOR_V),debugserver.xml)
	$(call SIGN,libclang-cpp$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,liblldb-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,libllvm$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,liblto$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,lldb-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,dsymutil-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,swift-$(SWIFT_VERSION),general.xml)
	$(call SIGN,llvm-utils-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,clang-tools-$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,libllvm-polly$(LLVM_MAJOR_V),general.xml)
	$(call SIGN,lld-$(LLVM_MAJOR_V),general.xml)

	# llvm.mk Make .debs
	$(call PACK,clang-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang,DEB_LLVM_V)
	$(call PACK,debugserver-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,debugserver,DEB_LLVM_V)
	$(call PACK,libc++-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,libc++-dev,DEB_LLVM_V)
	$(call PACK,libclang-common-$(LLVM_MAJOR_V)-dev,DEB_LLVM_V)
	$(call PACK,libclang-cpp$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,liblldb-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,libllvm$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,liblto$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,liblto,DEB_LLVM_V)
	$(call PACK,lldb-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,lldb,DEB_LLVM_V)
	$(call PACK,dsymutil-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,dsymutil,DEB_LLVM_V)
	$(call PACK,swift-$(SWIFT_VERSION),DEB_SWIFT_V)
	$(call PACK,swift,DEB_SWIFT_V)
	$(call PACK,llvm-utils-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,llvm-utils,DEB_LLVM_V)
	$(call PACK,clang-tools-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,clang-tools,DEB_LLVM_V)
	$(call PACK,libllvm-polly$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,lld-$(LLVM_MAJOR_V),DEB_LLVM_V)
	$(call PACK,lld,DEB_LLVM_V)

	# llvm.mk Build cleanup
	rm -rf $(BUILD_DIST)/{clang*,debugserver*,libc++*-dev,libclang-common-*-dev,libclang-cpp*,liblldb-*,libllvm*,liblto*,lldb*,dsymutil*,swift*,lld*,llvm-utils*}/

.PHONY: llvm llvm-package
