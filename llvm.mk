ifneq ($(PROCURSUS),1)
$(error Use the main Makellvm)
endif

SUBPROJECTS    += llvm
DOWNLOAD       += https://github.com/Diatrus/llvm-project/archive/v$(LLVM_VERSION).tar.gz \
			https://opensource.apple.com/tarballs/tapi/tapi-$(TAPI_VERSION).tar.gz
LLVM_VERSION   := 11.0.0
LLVM_MAJOR_V   := 11
TAPI_VERSION   := 1000.10.8
DEB_TAPI_V     ?= $(TAPI_VERSION)
DEB_LLVM_V     ?= $(LLVM_VERSION)
#-I$(BUILD_WORK)/llvm/src/llvm/projects/clang/include -I$(BUILD_WORK)/llvm/build/projects/clang/include
ifeq ($(MEMO_TARGET),iphoneos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-ios12.0
else ifeq ($(MEMO_TARGET),iphoneos-arm)
LLVM_DEFAULT_TRIPLE := arm-apple-ios8.0
else ifeq ($(MEMO_TARGET),appletvos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-tvos10.0
else ifeq ($(MEMO_TARGET),watchos-arm64)
LLVM_DEFAULT_TRIPLE := arm64-apple-watchos4.0
else ifeq ($(MEMO_TARGET),watchos-arm)
LLVM_DEFAULT_TRIPLE := armv7k-apple-watchos2.0
endif

llvm-setup: setup
	$(call EXTRACT_TAR,v$(LLVM_VERSION).tar.gz,llvm-project-$(LLVM_VERSION),llvm)
	$(call EXTRACT_TAR,tapi-$(TAPI_VERSION).tar.gz,tapi-$(TAPI_VERSION),llvm/llvm/projects/tapi)
	$(call DO_PATCH,tapi,llvm/llvm/projects/tapi,-p1)
	mkdir -p $(BUILD_WORK)/llvm/build

ifneq ($(wildcard $(BUILD_WORK)/llvm/.build_complete),)
llvm:
	@echo "Using previously built llvm."
else
llvm: llvm-setup
	+if [ ! -f "$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" ]; then \
		rm -rf $(BUILD_WORK)/../../native/llvm; \
		mkdir -p $(BUILD_WORK)/../../native/llvm; \
		cd $(BUILD_WORK)/../../native/llvm && unset CC CXX CPP AR RANLIB CFLAGS CXXFLAGS CPPFLAGS LDFLAGS && CC=clang CXX=clang++ cmake . -j$(shell $(GET_LOGICAL_CORES)) \
			-DCMAKE_BUILD_TYPE=Release \
			-DLLVM_ENABLE_PROJECTS="clang;lldb" \
			-DLLVM_INCLUDE_TESTS=OFF \
			$(BUILD_WORK)/llvm/llvm; \
		env -i $(MAKE) -C $(BUILD_WORK)/../../native/llvm llvm-tblgen clang-tblgen lldb-tblgen; \
	fi
	cd $(BUILD_WORK)/llvm/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib/llvm-$(LLVM_MAJOR_V)/lib \
		-DCMAKE_INSTALL_RPATH=/usr/lib/llvm-$(LLVM_MAJOR_V) \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DCLANG_VERSION=$(LLVM_VERSION) \
		-DLLDB_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/lldb-tblgen" \
		-DLLVM_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/llvm-tblgen" \
		-DCLANG_TABLEGEN="$(BUILD_WORK)/../../native/llvm/bin/clang-tblgen" \
		-DCLANG_TABLEGEN_EXE="$(BUILD_WORK)/../../native/llvm/bin/clang-tblgen" \
		-DLLVM_BUILD_LLVM_DYLIB=ON \
		-DLLVM_LINK_LLVM_DYLIB=ON \
		-DCLANG_LINK_CLANG_DYLIB=ON \
		-DLIBCXX_OVERRIDE_DARWIN_INSTALL=ON \
		-DLLVM_VERSION_SUFFIX="" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_DEFAULT_TRIPLE) \
		-DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lldb;tapi" \
		-DLLVM_INCLUDE_TESTS=OFF \
		../llvm
	+$(MAKE) -C $(BUILD_WORK)/llvm/build clang
	+$(MAKE) -C $(BUILD_WORK)/llvm/build
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
