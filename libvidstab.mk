ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libvidstab
LIBVIDSTAB_VERSION := 1.1.0
DEB_LIBVIDSTAB_V   ?= $(LIBVIDSTAB_VERSION)

libvidstab-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/vid.stab-$(LIBVIDSTAB_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/vid.stab-$(LIBVIDSTAB_VERSION).tar.gz \
			https://github.com/georgmartius/vid.stab/archive/v$(LIBVIDSTAB_VERSION).tar.gz
	$(call EXTRACT_TAR,vid.stab-$(LIBVIDSTAB_VERSION).tar.gz,vid.stab-$(LIBVIDSTAB_VERSION),libvidstab)

ifneq ($(wildcard $(BUILD_WORK)/libvidstab/.build_complete),)
libvidstab:
	@echo "Using previously built libvidstab."
else
libvidstab: libvidstab-setup
	cd $(BUILD_WORK)/libvidstab && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DUSE_OMP=OFF \
		-DSSE2_FOUND=FALSE
	+$(MAKE) -C $(BUILD_WORK)/libvidstab
	+$(MAKE) -C $(BUILD_WORK)/libvidstab install \
		DESTDIR=$(BUILD_STAGE)/libvidstab
	+$(MAKE) -C $(BUILD_WORK)/libvidstab install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libvidstab/.build_complete
endif

libvidstab-package: libvidstab-stage
	# libvidstab.mk Package Structure
	rm -rf $(BUILD_DIST)/libvidstab{1.1,-dev}
	mkdir -p $(BUILD_DIST)/libvidstab{1.1,-dev}/usr/lib
	
	# libvidstab.mk Prep libvidstab1.1
	cp -a $(BUILD_STAGE)/libvidstab/usr/lib/libvidstab.1.1.dylib $(BUILD_DIST)/libvidstab1.1/usr/lib
	
	# libvidstab.mk Prep libvidstab-dev
	cp -a $(BUILD_STAGE)/libvidstab/usr/lib/!(libvidstab.1.1.dylib) $(BUILD_DIST)/libvidstab-dev/usr/lib
	cp -a $(BUILD_STAGE)/libvidstab/usr/include $(BUILD_DIST)/libvidstab-dev/usr
	
	# libvidstab.mk Sign
	$(call SIGN,libvidstab1.1,general.xml)
	
	# libvidstab.mk Make .debs
	$(call PACK,libvidstab1.1,DEB_LIBVIDSTAB_V)
	$(call PACK,libvidstab-dev,DEB_LIBVIDSTAB_V)
	
	# libvidstab.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvidstab{1.1,-dev}

.PHONY: libvidstab libvidstab-package
