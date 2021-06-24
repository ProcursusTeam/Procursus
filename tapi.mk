ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tapi
TAPI_COMMIT    := 664b8414f89612f2dfd35a9b679c345aa5389026
TAPI_VERSION   := 1100.0.11
DEB_TAPI_V     ?= $(TAPI_VERSION)-1

tapi-setup: setup
	$(call GITHUB_ARCHIVE,tpoechtrager,apple-libtapi,$(TAPI_COMMIT),$(TAPI_COMMIT),tapi)
	$(call EXTRACT_TAR,tapi-$(TAPI_COMMIT).tar.gz,apple-libtapi-$(TAPI_COMMIT),tapi)
	mkdir -p $(BUILD_WORK)/tapi/build

ifneq ($(wildcard $(BUILD_WORK)/tapi/.build_complete),)
tapi:
	@echo "Using previously built tapi."
else
tapi: tapi-setup
	mkdir -p $(BUILD_WORK)/tapi/build/NATIVE && cd $(BUILD_WORK)/tapi/build/NATIVE && cmake . \
		-DCMAKE_C_COMPILER=cc \
		-DCMAKE_CXX_COMPILER=c++ \
		-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)" \
		-DCMAKE_C_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_CXX_FLAGS="" \
		-DCMAKE_EXE_LINKER_FLAGS="" \
		-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
		../../src/llvm
	+$(MAKE) -C $(BUILD_WORK)/tapi/build/NATIVE llvm-tblgen clang-tblgen

	cd $(BUILD_WORK)/tapi/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS) -I$(BUILD_WORK)/tapi/src/llvm/projects/clang/include -I$(BUILD_WORK)/tapi/build/projects/clang/include" \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="";-DCMAKE_CXX_FLAGS="";-DCMAKE_EXE_LINKER_FLAGS="";-DLLVM_INCLUDE_TESTS=OFF;-DTAPI_INCLUDE_TESTS=OFF' \
		-DLLVM_ENABLE_PROJECTS="libtapi" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DTAPI_FULL_VERSION=$(TAPI_VERSION) \
		-DTAPI_INCLUDE_TESTS=OFF \
		-DLLVM_TABLEGEN="$(BUILD_WORK)/tapi/build/NATIVE/bin/llvm-tblgen" \
		-DCLANG_TABLEGEN="$(BUILD_WORK)/tapi/build/NATIVE/bin/clang-tblgen" \
		-DCLANG_TABLEGEN_EXE="$(BUILD_WORK)/tapi/build/NATIVE/bin/clang-tblgen" \
		../src/llvm
	+$(MAKE) -C $(BUILD_WORK)/tapi/build libtapi tapi
	+$(MAKE) -C $(BUILD_WORK)/tapi/build install-libtapi install-tapi-headers install-tapi \
		DESTDIR="$(BUILD_STAGE)/tapi"
	mkdir -p $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(INSTALL) -Dm644 $(BUILD_WORK)/tapi/src/libtapi/docs/man/*.1 $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/tapi/.build_complete
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
