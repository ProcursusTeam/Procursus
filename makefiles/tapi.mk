ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tapi
TAPI_LLVM_TAG  := swift-DEVELOPMENT-SNAPSHOT-2023-09-05-a
TAPI_VERSION   := 1500.0.12.3
DEB_TAPI_V     ?= $(TAPI_VERSION)

tapi-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,tapi,$(TAPI_VERSION),tapi-$(TAPI_VERSION))
	$(call GITHUB_ARCHIVE,apple,llvm-project,$(TAPI_LLVM_TAG),$(TAPI_LLVM_TAG),llvm-project-tapi)
	$(call EXTRACT_TAR,llvm-project-tapi-$(TAPI_LLVM_TAG).tar.gz,llvm-project-$(TAPI_LLVM_TAG),tapi)
	$(call EXTRACT_TAR,tapi-$(TAPI_VERSION).tar.gz,tapi-tapi-$(TAPI_VERSION),tapi/tapi)
	mkdir -p $(BUILD_WORK)/tapi/build
	sed -i 's| -allowable_client ld||' $(BUILD_WORK)/tapi/tapi/tools/libtapi/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/tapi/.build_complete),)
tapi:
	@echo "Using previously built tapi."
else
tapi: tapi-setup
	mkdir -p $(BUILD_WORK)/tapi/build/NATIVE && cd $(BUILD_WORK)/tapi/build/NATIVE && cmake \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=cc \
		-DCMAKE_CXX_COMPILER=c++ \
		-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)" \
		-DCMAKE_C_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_EXE_LINKER_FLAGS="" \
		-DLLVM_ENABLE_PROJECTS="clang" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
		../../llvm
	+$(MAKE) -C $(BUILD_WORK)/tapi/build/NATIVE llvm-tblgen clang-tblgen

	cd $(BUILD_WORK)/tapi/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS) -I$(BUILD_WORK)/tapi/src/llvm/projects/clang/include -I$(BUILD_WORK)/tapi/build/projects/clang/include" \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="";-DCMAKE_CXX_FLAGS="";-DCMAKE_EXE_LINKER_FLAGS="";-DLLVM_INCLUDE_TESTS=OFF;-DTAPI_INCLUDE_TESTS=OFF' \
		-DLLVM_ENABLE_PROJECTS="clang;tapi" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DTAPI_FULL_VERSION=$(TAPI_VERSION) \
		-DTAPI_INCLUDE_TESTS=OFF \
		-DLLVM_TABLEGEN="$(BUILD_WORK)/tapi/build/NATIVE/bin/llvm-tblgen" \
		-DCLANG_TABLEGEN="$(BUILD_WORK)/tapi/build/NATIVE/bin/clang-tblgen" \
		-DCLANG_TABLEGEN_EXE="$(BUILD_WORK)/tapi/build/NATIVE/bin/clang-tblgen" \
		../llvm
	+$(MAKE) -C $(BUILD_WORK)/tapi/build ClangDeclNodes libtapi tapi
	+$(MAKE) -C $(BUILD_WORK)/tapi/build install-libtapi install-tapi-headers install-tapi \
		DESTDIR="$(BUILD_STAGE)/tapi"
	mkdir -p $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(INSTALL) -Dm644 $(BUILD_WORK)/tapi/tapi/docs/man/*.1 $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD,copy)
endif

tapi-package: tapi-stage
	# tapi.mk Package Structure
	rm -rf $(BUILD_DIST)/tapi $(BUILD_DIST)/libtapi{,-dev}
	mkdir -p $(BUILD_DIST)/libtapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libtapi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# tapi.mk Prep tapi
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtapi.dylib $(BUILD_DIST)/libtapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtapi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tapi $(BUILD_DIST)/libtapi-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# tapi.mk Sign
	$(call SIGN,libtapi,general.xml)
	$(call SIGN,tapi,general.xml)

	# tapi.mk Make .debs
	$(call PACK,libtapi,DEB_TAPI_V)
	$(call PACK,libtapi-dev,DEB_TAPI_V)
	$(call PACK,tapi,DEB_TAPI_V)

	# tapi.mk Build cleanup
	rm -rf $(BUILD_DIST)/tapi $(BUILD_DIST)/libtapi{,-dev}

.PHONY: tapi tapi-package
