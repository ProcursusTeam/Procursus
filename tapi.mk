ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += tapi
TAPI_COMMIT    := 664b8414f89612f2dfd35a9b679c345aa5389026
TAPI_VERSION   := 1100.0.11
DEB_TAPI_V     ?= $(TAPI_VERSION)

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
	touch $(BUILD_WORK)/tapi/.build_complete
endif

tapi-package: tapi-stage
	# tapi.mk Package Structure
	rm -rf $(BUILD_DIST)/libtapi
	mkdir -p $(BUILD_DIST)/libtapi

	# tapi.mk Prep tapi
	cp -a $(BUILD_STAGE)/tapi/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/libtapi

	# tapi.mk Sign
	$(call SIGN,libtapi,general.xml)

	# tapi.mk Make .debs
	$(call PACK,libtapi,DEB_TAPI_V)

	# tapi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtapi

.PHONY: tapi tapi-package
