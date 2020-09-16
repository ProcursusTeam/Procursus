ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

#SUBPROJECTS   += tapi
TAPI_VERSION   := 1100.0.11
DEB_TAPI_V     ?= $(TAPI_VERSION)

tapi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Diatrus/apple-libtapi/archive/v$(TAPI_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(TAPI_VERSION).tar.gz,apple-libtapi-$(TAPI_VERSION),tapi)
	mkdir -p $(BUILD_WORK)/tapi/build

ifneq ($(wildcard $(BUILD_WORK)/tapi/.build_complete),)
tapi:
	@echo "Using previously built tapi."
else
tapi: tapi-setup
	ln -sf $(BUILD_BASE)/usr/lib/libncursesw.dylib $(BUILD_BASE)/usr/lib/libcurses.dylib
	cd $(BUILD_WORK)/tapi/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_ARCHITECTURES="$(ARCHES)" \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
		-DCMAKE_CXX_FLAGS="-isystem $(BUILD_BASE)/usr/include -isystem $(BUILD_BASE)/usr/local/include $(PLATFORM_VERSION_MIN) -I $(BUILD_WORK)/tapi/src/llvm/projects/clang/include -I $(BUILD_WORK)/tapi/build/projects/clang/include" \
		-DCMAKE_EXE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_MODULE_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_SHARED_LINKER_FLAGS="-L$(BUILD_BASE)/usr/lib -L$(BUILD_BASE)/usr/local/lib -F$(BUILD_BASE)/System/Library/Frameworks" \
		-DCMAKE_STATIC_LINKER_FLAGS="" \
		-DCROSS_TOOLCHAIN_FLAGS_NATIVE='-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_OSX_SYSROOT="$(MACOSX_SYSROOT)";-DCMAKE_OSX_ARCHITECTURES="";-DCMAKE_C_FLAGS="";-DCMAKE_CXX_FLAGS="";-DCMAKE_EXE_LINKER_FLAGS="";-DLLVM_INCLUDE_TESTS=OFF;-DTAPI_INCLUDE_TESTS=OFF' \
		-DLLVM_ENABLE_PROJECTS="libtapi" \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DTAPI_FULL_VERSION=$(TAPI_VERSION) \
		-DTAPI_INCLUDE_TESTS=OFF \
		../src/llvm
	+$(MAKE) -C $(BUILD_WORK)/tapi/build clangBasic
	+$(MAKE) -C $(BUILD_WORK)/tapi/build libtapi
	+$(MAKE) -C $(BUILD_WORK)/tapi/build install-libtapi install-tapi-headers \
		DESTDIR="$(BUILD_STAGE)/tapi"
	rm -rf $(BUILD_BASE)/usr/lib/libcurses.dylib
	touch $(BUILD_WORK)/tapi/.build_complete
endif

tapi-package: tapi-stage
	# tapi.mk Package Structure
	rm -rf $(BUILD_DIST)/libtapi
	mkdir -p $(BUILD_DIST)/libtapi
	
	# tapi.mk Prep tapi
	cp -a $(BUILD_STAGE)/tapi/usr $(BUILD_DIST)/libtapi
	
	# tapi.mk Sign
	$(call SIGN,libtapi,general.xml)
	
	# tapi.mk Make .debs
	$(call PACK,libtapi,DEB_TAPI_V)
	
	# tapi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtapi

.PHONY: tapi tapi-package
