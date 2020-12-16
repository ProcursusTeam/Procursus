ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += openexr
OPENEXR_VERSION := 2.5.3
DEB_OPENEXR_V   ?= $(OPENEXR_VERSION)

openexr-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/openexr-$(OPENEXR_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/openexr-$(OPENEXR_VERSION).tar.gz \
			https://github.com/openexr/openexr/archive/v$(OPENEXR_VERSION).tar.gz
	$(call EXTRACT_TAR,openexr-$(OPENEXR_VERSION).tar.gz,openexr-$(OPENEXR_VERSION),openexr) 
ifneq ($(wildcard $(BUILD_WORK)/openexr/.build_complete),)
openexr:
	@echo "Using previously built openexr."
else
openexr: openexr-setup
	cd $(BUILD_WORK)/openexr/IlmBase && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DBUILD_TESTING=OFF \
		.
	+$(MAKE) -C $(BUILD_WORK)/openexr/IlmBase install \
		DESTDIR="$(BUILD_STAGE)/ilmbase"
	+$(MAKE) -C $(BUILD_WORK)/openexr/IlmBase install \
		DESTDIR="$(BUILD_BASE)"

	cd $(BUILD_WORK)/openexr/OpenEXR && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		.
	+$(MAKE) -C $(BUILD_WORK)/openexr/OpenEXR install \
		DESTDIR="$(BUILD_STAGE)/openexr"
	+$(MAKE) -C $(BUILD_WORK)/openexr/OpenEXR install \
		DESTDIR="$(BUILD_BASE)"
	
	touch $(BUILD_WORK)/openexr/.build_complete
endif

openexr-package: openexr-stage
	# openexr.mk Package Structure
	rm -rf $(BUILD_DIST)/openexr \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}
	mkdir -p $(BUILD_DIST)/openexr/usr \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}/usr/lib
	
	# openexr.mk Prep openexr
	cp -a $(BUILD_STAGE)/openexr/usr/bin $(BUILD_DIST)/openexr/usr
	
	# openexr.mk Prep libopenexr25
	cp -a $(BUILD_STAGE)/openexr/usr/lib/libIlmImf{,Util}-2_5.*.dylib $(BUILD_DIST)/libopenexr25/usr/lib
	
	# openexr.mk Prep libopenexr-dev
	cp -a $(BUILD_STAGE)/openexr/usr/lib/{libIlmImf{,Util}{-2_5,}.dylib,pkgconfig,cmake} $(BUILD_DIST)/libopenexr-dev/usr/lib
	cp -a $(BUILD_STAGE)/openexr/usr/include $(BUILD_DIST)/libopenexr-dev/usr
	
	# openexr.mk Prep libilmbase25
	cp -a $(BUILD_STAGE)/ilmbase/usr/lib/lib{Half,Iex,IexMath,IlmThread,Imath}-2_5.*.dylib $(BUILD_DIST)/libilmbase25/usr/lib
	
	# openexr.mk Prep libilmbase-dev
	cp -a $(BUILD_STAGE)/ilmbase/usr/lib/{lib{Half,Iex,IexMath,IlmThread,Imath}{-2_5,}.dylib,pkgconfig,cmake} $(BUILD_DIST)/libilmbase-dev/usr/lib
	cp -a $(BUILD_STAGE)/ilmbase/usr/include $(BUILD_DIST)/libilmbase-dev/usr
	
	# openexr.mk Sign
	$(call SIGN,openexr,general.xml)
	$(call SIGN,libopenexr25,general.xml)
	$(call SIGN,libilmbase25,general.xml)
	
	# openexr.mk Make .debs
	$(call PACK,openexr,DEB_OPENEXR_V)
	$(call PACK,libopenexr25,DEB_OPENEXR_V)
	$(call PACK,libopenexr-dev,DEB_OPENEXR_V)
	$(call PACK,libilmbase25,DEB_OPENEXR_V)
	$(call PACK,libilmbase-dev,DEB_OPENEXR_V)
	
	# openexr.mk Build cleanup
	rm -rf $(BUILD_DIST)/openexr \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}

.PHONY: openexr openexr-package
