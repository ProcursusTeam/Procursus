ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += openmp
OPENMP_VERSION := 12.0.0
DEB_OPENMP_V   ?= $(OPENMP_VERSION)

openmp-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/llvm/llvm-project/releases/download/llvmorg-$(OPENMP_VERSION)/openmp-$(OPENMP_VERSION).src.tar.xz)
	$(call EXTRACT_TAR,openmp-$(OPENMP_VERSION).src.tar.xz,openmp-$(OPENMP_VERSION).src,openmp)

ifneq ($(wildcard $(BUILD_WORK)/openmp/.build_complete),)
openmp:
	@echo "Using previously built openmp."
else
openmp: openmp-setup
	# Shared lib
	cd $(BUILD_WORK)/openmp && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DLIBOMP_INSTALL_ALIASES=OFF \
		-DLIBOMP_LIB_NAME=libomp.1 \
		.
	+$(MAKE) -C $(BUILD_WORK)/openmp
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_STAGE)/openmp"

	$(LN_S) libomp.1.dylib $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libomp.dylib

	# Static lib
	cd $(BUILD_WORK)/openmp && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DLIBOMP_INSTALL_ALIASES=OFF \
		-DLIBOMP_ENABLE_SHARED=OFF \
		-DLIBOMP_LIB_NAME=libomp \
		.
	+$(MAKE) -C $(BUILD_WORK)/openmp
	+$(MAKE) -C $(BUILD_WORK)/openmp install \
		DESTDIR="$(BUILD_STAGE)/openmp"
	$(call AFTER_BUILD,copy)
endif

openmp-package: openmp-stage
	# openmp.mk Package Structure
	rm -rf $(BUILD_DIST)/libomp{1,-dev}
	mkdir -p $(BUILD_DIST)/libomp{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openmp.mk Prep libomp1
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libomp.1.dylib $(BUILD_DIST)/libomp1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openmp.mk Prep libomp-dev
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libomp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/openmp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libomp.1.dylib) $(BUILD_DIST)/libomp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openmp.mk Sign
	$(call SIGN,libomp1,general.xml)

	# openmp.mk Make .debs
	$(call PACK,libomp1,DEB_OPENMP_V)
	$(call PACK,libomp-dev,DEB_OPENMP_V)

	# openmp.mk Build cleanup
	rm -rf $(BUILD_DIST)/libomp{1,-dev}

.PHONY: openmp openmp-package
