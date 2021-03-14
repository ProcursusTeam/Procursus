ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += openmp
OPENMP_VERSION := 11.0.0
DEB_OPENMP_V   ?= $(OPENMP_VERSION)

openmp-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/llvm/llvm-project/releases/download/llvmorg-$(OPENMP_VERSION)/openmp-$(OPENMP_VERSION).src.tar.xz
	$(call EXTRACT_TAR,openmp-$(OPENMP_VERSION).src.tar.xz,openmp-$(OPENMP_VERSION).src,openmp)
	$(call DO_PATCH,openmp,openmp,-p1)

ifneq ($(wildcard $(BUILD_WORK)/openmp/.build_complete),)
openmp:
	@echo "Using previously built openmp."
else
openmp: openmp-setup
	# Shared lib
	cd $(BUILD_WORK)/openmp && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DLIBOMP_INSTALL_ALIASES=OFF \
		-DLIBOMP_LIB_NAME=libomp.1 \
		.
	+$(MAKE) -C $(BUILD_WORK)/openmp
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_STAGE)/openmp"
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_BASE)"

	ln -sf libomp.1.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libomp.dylib
	ln -sf libomp.1.dylib $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libomp.dylib

	# Static lib
	cd $(BUILD_WORK)/openmp && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DLIBOMP_INSTALL_ALIASES=OFF \
		-DLIBOMP_ENABLE_SHARED=OFF \
		-DLIBOMP_LIB_NAME=libomp \
		.
	+$(MAKE) -C $(BUILD_WORK)/openmp
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_STAGE)/openmp"
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/openmp/.build_complete
endif

openmp-package: openmp-stage
	# openmp.mk Package Structure
	rm -rf $(BUILD_DIST)/libomp{1,-dev}
	mkdir -p $(BUILD_DIST)/libomp{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# openmp.mk Prep libomp1
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libomp.1.dylib $(BUILD_DIST)/libomp1/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# openmp.mk Prep libomp-dev
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libomp-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/!(libomp.1.dylib) $(BUILD_DIST)/libomp-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# openmp.mk Sign
	$(call SIGN,libomp1,general.xml)
	
	# openmp.mk Make .debs
	$(call PACK,libomp1,DEB_OPENMP_V)
	$(call PACK,libomp-dev,DEB_OPENMP_V)
	
	# openmp.mk Build cleanup
	rm -rf $(BUILD_DIST)/libomp{1,-dev}

.PHONY: openmp openmp-package
