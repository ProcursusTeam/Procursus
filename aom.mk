ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += aom
AOM_VERSION   := 2.0.1
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
		-DAOM_TARGET_CPU="$(ARCHES)" \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
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
	mkdir -p $(BUILD_DIST)/aom-tools/usr/ \
		$(BUILD_DIST)/libaom{2,-dev}/usr/lib
	
	# aom.mk Prep aom-tools
	cp -a $(BUILD_STAGE)/aom/usr/bin $(BUILD_DIST)/aom-tools/usr
	
	# aom.mk Prep libaom2
	cp -a $(BUILD_STAGE)/aom/usr/lib/libaom.2.0.0.dylib $(BUILD_DIST)/libaom2/usr/lib
	cp -a $(BUILD_STAGE)/aom/usr/lib/libaom.2.dylib $(BUILD_DIST)/libaom2/usr/lib
	
	# aom.mk Prep libaom-pkg-dev
	cp -a $(BUILD_STAGE)/aom/usr/lib/libaom.{dylib,a} $(BUILD_DIST)/libaom-dev/usr/lib
	cp -a $(BUILD_STAGE)/aom/usr/lib/pkgconfig $(BUILD_DIST)/libaom-dev/usr/lib
	cp -a $(BUILD_STAGE)/aom/usr/include $(BUILD_DIST)/libaom-dev/usr
	
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
