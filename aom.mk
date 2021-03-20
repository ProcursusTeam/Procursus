ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += aom
AOM_VERSION   := 2.0.2
DEB_AOM_V     ?= $(AOM_VERSION)

aom-setup: setup
	if [ ! -d "$(BUILD_WORK)/aom" ]; then \
		git clone https://aomedia.googlesource.com/aom.git $(BUILD_WORK)/aom; \
		cd "$(BUILD_WORK)/aom"; \
		git fetch origin; \
		git reset --hard origin/master; \
		git checkout v$(AOM_VERSION); \
		git submodule update --init; \
	fi

ifneq ($(wildcard $(BUILD_WORK)/aom/.build_complete),)
aom:
	@echo "Using previously built aom."
else
aom: aom-setup
	cd $(BUILD_WORK)/aom/build && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DBUILD_SHARED_LIBS=1 \
		-DCONFIG_RUNTIME_CPU_DETECT=0 \
		-DENABLE_TESTS=0 \
		-DGIT_EXECUTABLE=/non-existant-binary \
		-DAOM_TARGET_CPU="$(MEMO_ARCH)" \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		..
	+$(MAKE) -C $(BUILD_WORK)/aom/build
	+$(MAKE) -C $(BUILD_WORK)/aom/build install \
		DESTDIR="$(BUILD_STAGE)/aom"
	+$(MAKE) -C $(BUILD_WORK)/aom/build install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/aom/.build_complete
endif

aom-package: aom-stage
	# aom.mk Package Structure
	rm -rf $(BUILD_DIST)/aom-tools $(BUILD_DIST)/libaom{2,-dev}
	mkdir -p $(BUILD_DIST)/aom-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ \
		$(BUILD_DIST)/libaom{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# aom.mk Prep aom-tools
	cp -a $(BUILD_STAGE)/aom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/aom-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# aom.mk Prep libaom2
	cp -a $(BUILD_STAGE)/aom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaom.2*.dylib $(BUILD_DIST)/libaom2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# aom.mk Prep libaom-pkg-dev
	cp -a $(BUILD_STAGE)/aom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaom.{dylib,a} $(BUILD_DIST)/libaom-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/aom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libaom-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/aom/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libaom-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# aom.mk Sign
	$(call SIGN,aom-tools,general.xml)
	$(call SIGN,libaom2,general.xml)
	
	# aom.mk Make .debs
	$(call PACK,aom-tools,DEB_AOM_V)
	$(call PACK,libaom2,DEB_AOM_V)
	$(call PACK,libaom-dev,DEB_AOM_V)
	
	# aom.mk Build cleanup
	rm -rf $(BUILD_DIST)/aom-tools $(BUILD_DIST)/libaom{2,-dev}
	
.PHONY: aom aom-package
