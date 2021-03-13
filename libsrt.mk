ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libsrt
LIBSRT_VERSION := 1.4.2
DEB_LIBSRT_V   ?= $(LIBSRT_VERSION)-1

libsrt-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libsrt-$(LIBSRT_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libsrt-$(LIBSRT_VERSION).tar.gz \
			https://github.com/Haivision/srt/archive/v$(LIBSRT_VERSION).tar.gz
	$(call EXTRACT_TAR,libsrt-$(LIBSRT_VERSION).tar.gz,srt-$(LIBSRT_VERSION),libsrt)

ifneq ($(wildcard $(BUILD_WORK)/libsrt/.build_complete),)
libsrt:
	@echo "Using previously built libsrt."
else
libsrt: libsrt-setup openssl
	cd $(BUILD_WORK)/libsrt && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DBUILD_SHARED_LIBS=true \
		-DWITH_OPENSSL_INCLUDEDIR=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/openssl \
		-DWITH_OPENSSL_LIBDIR=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	+$(MAKE) -C $(BUILD_WORK)/libsrt install \
		DESTDIR=$(BUILD_STAGE)/libsrt
	+$(MAKE) -C $(BUILD_WORK)/libsrt install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libsrt/.build_complete
endif

libsrt-package: libsrt-stage
	# libsrt.mk Package Structure
	rm -rf $(BUILD_DIST)/libsrt{1,-dev} \
		$(BUILD_DIST)/srt-tools
	mkdir -p $(BUILD_DIST)/libsrt{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
		$(BUILD_DIST)/srt-tools/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# libsrt.mk Prep libsrt1
	cp -a $(BUILD_STAGE)/libsrt/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libsrt.{$(LIBSRT_VERSION),1}.dylib $(BUILD_DIST)/libsrt1/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# libsrt.mk Prep libsrt-dev
	cp -a $(BUILD_STAGE)/libsrt/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libsrt.{dylib,a} $(BUILD_DIST)/libsrt-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	cp -a $(BUILD_STAGE)/libsrt/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libsrt-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/libsrt/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/pkgconfig $(BUILD_DIST)/libsrt-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# libsrt.mk Prep srt-tools
	cp -a $(BUILD_STAGE)/libsrt/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin $(BUILD_DIST)/srt-tools/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)

	# libsrt.mk Sign
	$(call SIGN,libsrt1,general.xml)
	$(call SIGN,srt-tools,general.xml)
	
	# libsrt.mk Make .debs
	$(call PACK,libsrt1,DEB_LIBSRT_V)
	$(call PACK,libsrt-dev,DEB_LIBSRT_V)
	$(call PACK,srt-tools,DEB_LIBSRT_V)
	
	# libsrt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsrt{1,-dev} \
		$(BUILD_DIST)/srt-tools

.PHONY: libsrt libsrt-package
