ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += xpwn
XPWN_VERSION := 0.5.8+git20201205.$(shell echo $(XPWN_COMMIT) | cut -c -7)
DEB_XPWN_V   ?= $(XPWN_VERSION)

XPWN_COMMIT  := def39d6e0ed0fdec0a0ff526bd11bec15d8de4e7

xpwn-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/xpwn-v$(XPWN_COMMIT).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/xpwn-v$(XPWN_COMMIT).tar.gz \
			https://github.com/OothecaPickle/xpwn/archive/$(XPWN_COMMIT).tar.gz
	$(call EXTRACT_TAR,xpwn-v$(XPWN_COMMIT).tar.gz,xpwn-$(XPWN_COMMIT),xpwn)
	$(call DO_PATCH,xpwn,xpwn,-p1)

	$(SED) -i 's/powerpc-apple-darwin8-libtool/libtool/' $(BUILD_WORK)/xpwn/ipsw-patch/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/xpwn/.build_complete),)
xpwn:
	@echo "Using previously built xpwn."
else
xpwn: xpwn-setup libpng16 openssl
	cd $(BUILD_WORK)/xpwn && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DBZIP2_LIBRARIES="-L$(TARGET_SYSROOT)/usr/lib -lbz2" \
		-DZLIB_LIBRARY="-L$(TARGET_SYSROOT)/usr/lib -lz"
	+$(MAKE) -C $(BUILD_WORK)/xpwn
	+$(MAKE) -C $(BUILD_WORK)/xpwn install \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/xpwn install \
		DESTDIR=$(BUILD_STAGE)/xpwn
	mkdir -p $(BUILD_STAGE)/xpwn/usr/{include,lib}
	cp -a $(BUILD_WORK)/xpwn/includes/* {$(BUILD_BASE)/usr/include,$(BUILD_STAGE)/xpwn/usr/include}
	cp -a $(BUILD_WORK)/xpwn/{ipsw-patch/libxpwn,minizip/libminizip,common/libcommon,hfs/libhfs,dmg/libdmg}.a {$(BUILD_STAGE)/xpwn,$(BUILD_BASE)}/usr/lib
	touch $(BUILD_WORK)/xpwn/.build_complete
endif

xpwn-package: xpwn-stage
	# xpwn.mk Package Structure
	rm -rf $(BUILD_DIST)/{libxpwn-dev,xpwn}
	mkdir -p $(BUILD_DIST)/{libxpwn-dev,xpwn}

	# xpwn.mk Prep xpwn
	cp -a $(BUILD_STAGE)/xpwn/usr/bin $(BUILD_DIST)/xpwn/usr

	# xpwn.mk Prep libxpwn-dev
	cp -a $(BUILD_STAGE)/xpwn/usr/{include,lib} $(BUILD_DIST)/libxpwn-dev/usr
	
	# xpwn.mk Sign
	$(call SIGN,xpwn,general.xml)
	
	# xpwn.mk Make .debs
	$(call PACK,xpwn,DEB_XPWN_V)
	$(call PACK,libxpwn-dev,DEB_XPWN_V)
	
	# xpwn.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libxpwn-dev,xpwn}

.PHONY: xpwn xpwn-package
