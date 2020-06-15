ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS   += llvm
DOWNLOAD       += https://github.com/apple/llvm-project/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz
LLVM_VERSION   := 10.0.9
LLVM_MAJOR_V   := 10
SWIFT_VERSION  := 5.3
SWIFT_SUFFIX   := DEVELOPMENT-SNAPSHOT-2020-06-10-a
DEB_SWIFT_V    ?= $(SWIFT_VERSION)~$(SWIFT_SUFFIX)
DEB_LLVM_V     ?= $(LLVM_VERSION)

ifeq ($(MEMO_TARGET),iphoneos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-ios12.0
SWIFT_VARIANT       := IOS
SWIFT_OLD           := OFF
else ifeq ($(MEMO_TARGET),iphoneos-arm)
LLVM_DEFAULT_TRIPLE := arm-apple-ios8.0
SWIFT_VARIANT       := IOS
SWIFT_OLD           := ON
else ifeq ($(MEMO_TARGET),appletvos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-tvos10.0
SWIFT_VARIANT       := TVOS
SWIFT_OLD           := OFF
else ifeq ($(MEMO_TARGET),watchos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-watchos4.0
SWIFT_VARIANT       := WATCHOS
SWIFT_OLD           := OFF
else ifeq ($(MEMO_TARGET),watchos-arm)
LLVM_DEFAULT_TRIPLE := armv7k-apple-watchos2.0
SWIFT_VARIANT       := WATCHOS
SWIFT_OLD           := ON
endif

llvm-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz" ] && wget -O $(BUILD_SOURCE)/swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz https://github.com/apple/swift/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz
	-[ ! -e "$(BUILD_SOURCE)/swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz" ] && wget -O $(BUILD_SOURCE)/swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz https://github.com/apple/cmark/archive/swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz
	$(call EXTRACT_TAR,swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,llvm-project-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm)
	$(call EXTRACT_TAR,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/swift)
	$(call EXTRACT_TAR,swift-cmark-$(SWIFT_VERSION)-$(SWIFT_SUFFIX).tar.gz,swift-cmark-swift-$(SWIFT_VERSION)-$(SWIFT_SUFFIX),llvm/cmark)
	$(call DO_PATCH,llvm,llvm,-p1)
	$(call DO_PATCH,swift,llvm/swift,-p1)
	mkdir -p $(BUILD_WORK)/llvm/build
	$(SED) -i 's|isysroot $${CMAKE_OSX_SYSROOT}|isysroot $${CMAKE_FIND_ROOT_PATH}|' $(BUILD_WORK)/llvm/lldb/tools/debugserver/source/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/llvm/.build_complete),)
llvm:
	@echo "Using previously built llvm."
else
llvm: llvm-setup libffi ncurses xz
	cp -a $(SYSROOT)/usr/include/mach/arm $(BUILD_BASE)/usr/include/mach
	cp -a $(MACOSX_SYSROOT)/usr/include/{editline,kern} $(BUILD_BASE)/usr/include
	cp -a $(MACOSX_SYSROOT)/usr/include/histedit.h $(BUILD_BASE)/usr/include
	mv $(BUILD_BASE)/usr/include/stdlib.h $(BUILD_BASE)/usr/include/stdlib.h.old
	cd $(BUILD_WORK)/llvm/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=/usr/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_OSX_ARCHITECTURES="$(ARCHES)" \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
		-DCMAKE_C_FLAGS="-isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include $(PLATFORM_VERSION_MIN)" \
		-DCMAKE_CXX_FLAGS="-isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include $(PLATFORM_VERSION_MIN)" \
		-DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_MODULE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_SHARED_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_STATIC_LINKER_FLAGS="" \
		-DLLVM_ENABLE_FFI=ON \
		-DCURSES_NCURSES_LIBRARY="$(BUILD_BASE)/usr/lib/libncursesw.dylib" \
		-DLIBXML2_LIBRARY="$(SYSROOT)/usr/lib/libxml2.tbd" \
		-DLIBXML2_INCLUDE_DIR="$(SYSROOT)/usr/include/libxml" \
		-DLibEdit_INCLUDE_DIRS="$(BUILD_BASE)/usr/include" \
		-DLibEdit_LIBRARIES="$(SYSROOT)/usr/lib/libedit.tbd" \
		-DCORE_FOUNDATION_LIBRARY="$(SYSROOT)/System/Library/Frameworks/CoreFoundation.framework" \
		-DCORE_SERVICES_LIBRARY="$(SYSROOT)/System/Library/Frameworks/CoreServices.framework" \
		-DFOUNDATION_LIBRARY="$(SYSROOT)/System/Library/Frameworks/Foundation.framework" \
		-DFOUNDATION="$(SYSROOT)/System/Library/Frameworks/Foundation.framework" \
		-DSECURITY_LIBRARY="$(SYSROOT)/System/Library/Frameworks/Security.framework" \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="";-DCMAKE_CXX_FLAGS="";-DCMAKE_EXE_LINKER_FLAGS=""' \
		-DCLANG_VERSION=$(LLVM_VERSION) \
		-DLLVM_BUILD_LLVM_DYLIB=ON \
		-DLLVM_LINK_LLVM_DYLIB=ON \
		-DCLANG_LINK_CLANG_DYLIB=ON \
		-DLIBCXX_OVERRIDE_DARWIN_INSTALL=ON \
		-DLLVM_VERSION_SUFFIX="" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_DEFAULT_TRIPLE) \
		-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
		-DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lldb;cmark;swift" \
		-DLLVM_EXTERNAL_PROJECTS="cmark;swift" \
		-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR="$(BUILD_WORK)/llvm/swift" \
		-DLLVM_EXTERNAL_CMARK_SOURCE_DIR="$(BUILD_WORK)/llvm/cmark" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DMIG_ARCHS=$(ARCHES) \
		-DCFLAGS_SDK="$(SWIFT_VARIANT)" \
		-DCFLAGS_DEPLOYMENT_VERSION_IOS=12.0 \
		-DCFLAGS_DEPLOYMENT_VERSION_TVOS=10.0 \
		-DCFLAGS_DEPLOYMENT_VERSION_WATCHOS=4.0 \
		-DSWIFT_PRIMARY_VARIANT_SDK="$(SWIFT_VARIANT)" \
		-DSWIFT_PRIMARY_VARIANT_ARCH="$(ARCHES)" \
		-DSWIFT_HOST_VARIANT_SDK="$(SWIFT_VARIANT)" \
		-DSWIFT_HOST_VARIANT="$(PLATFORM)" \
		-DSWIFT_HOST_VARIANT_ARCH="$(ARCHES)" \
		-DSWIFT_ENABLE_IOS32="$(SWIFT_OLD)" \
		-DSWIFT_INCLUDE_TESTS=OFF \
		-DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
		-DSWIFT_BUILD_REMOTE_MIRROR=FALSE \
		-DSWIFT_BUILD_DYNAMIC_STDLIB=FALSE \
		-DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=FALSE \
		../llvm
	$(SED) -i 's|-lncurses|-lncursesw|' $(BUILD_WORK)/llvm/build/CMakeCache.txt
	+$(MAKE) -C $(BUILD_WORK)/llvm/build install \
		DESTDIR="$(BUILD_STAGE)/llvm"
	mv $(BUILD_BASE)/usr/include/stdlib.h.old $(BUILD_BASE)/usr/include/stdlib.h
	touch $(BUILD_WORK)/llvm/.build_complete
endif

llvm-package: llvm-stage
	# llvm.mk Package Structure
	rm -rf $(BUILD_DIST)/llvm
	mkdir -p $(BUILD_DIST)/llvm
	
	# llvm.mk Prep llvm
	cp -a $(BUILD_STAGE)/llvm/usr $(BUILD_DIST)/llvm
	
	# llvm.mk Sign
	$(call SIGN,llvm,general.xml)
	
	# llvm.mk Make .debs
	$(call PACK,llvm,DEB_LLVM_V)
	
	# llvm.mk Build cleanup
	rm -rf $(BUILD_DIST)/llvm

.PHONY: llvm llvm-package
