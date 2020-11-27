ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += openjpeg
OPENJPEG_VERSION := 2.3.1
DEB_OPENJPEG_V   ?= $(OPENJPEG_VERSION)

openjpeg-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/openjpeg-$(OPENJPEG_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/openjpeg-$(OPENJPEG_VERSION).tar.gz \
			https://github.com/uclouvain/openjpeg/archive/v$(OPENJPEG_VERSION).tar.gz
	$(call EXTRACT_TAR,openjpeg-$(OPENJPEG_VERSION).tar.gz,openjpeg-$(OPENJPEG_VERSION),openjpeg)

ifneq ($(wildcard $(BUILD_WORK)/openjpeg/.build_complete),)
openjpeg:
	@echo "Using previously built openjpeg."
else
openjpeg: openjpeg-setup libpng16 libtiff lcms2
	cd $(BUILD_WORK)/openjpeg && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/openjpeg
	+$(MAKE) -C $(BUILD_WORK)/openjpeg install \
		DESTDIR="$(BUILD_STAGE)/openjpeg"
	+$(MAKE) -C $(BUILD_WORK)/openjpeg install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/openjpeg/.build_complete
endif

openjpeg-package: openjpeg-stage
  # openjpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/libopenjp2-{7{,-dev},tools}
	mkdir -p \
		$(BUILD_DIST)/libopenjp2-7{,-dev}/usr/lib \
		$(BUILD_DIST)/libopenjp2-tools/usr

  # openjpeg.mk Prep libopenjp2-7-dev
	cp -a $(BUILD_STAGE)/openjpeg/usr/include $(BUILD_DIST)/libopenjp2-7-dev/usr
	cp -a $(BUILD_STAGE)/openjpeg/usr/lib/!(libopenjp2.*.dylib) $(BUILD_DIST)/libopenjp2-7-dev/usr/lib

  # openjpeg.mk Prep libopenjp2-tools
	cp -a $(BUILD_STAGE)/openjpeg/usr/bin $(BUILD_DIST)/libopenjp2-tools/usr

  # openjpeg.mk Prep libopenjp2-7
	cp -a $(BUILD_STAGE)/openjpeg/usr/lib/libopenjp2.{7,$(OPENJPEG_VERSION)}.dylib $(BUILD_DIST)/libopenjp2-7/usr/lib

  # openjpeg.mk Sign
	$(call SIGN,libopenjp2-7,general.xml)
	$(call SIGN,libopenjp2-tools,general.xml)

  # openjpeg.mk Make .debs
	$(call PACK,libopenjp2-7-dev,DEB_OPENJPEG_V)
	$(call PACK,libopenjp2-tools,DEB_OPENJPEG_V)
	$(call PACK,libopenjp2-7,DEB_OPENJPEG_V)

  # openjpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/libopenjp2-{7{,-dev},tools}

.PHONY: openjpeg openjpeg-package
