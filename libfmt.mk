ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libfmt
LIBFMT_VERSION  := 7.1.3
DEB_LIBFMT_V    ?= $(LIBFMT_VERSION)

libfmt-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libfmt-$(LIBFMT_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libfmt-$(LIBFMT_VERSION).tar.gz \
			https://github.com/fmtlib/fmt/archive/$(LIBFMT_VERSION).tar.gz
	$(call EXTRACT_TAR,libfmt-$(LIBFMT_VERSION).tar.gz,fmt-$(LIBFMT_VERSION),libfmt)

ifneq ($(wildcard $(BUILD_WORK)/libfmt/.build_complete),)
libfmt:
	@echo "Using previously built libfmt."
else
libfmt: libfmt-setup
	cd $(BUILD_WORK)/libfmt && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_CXX_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DBUILD_SHARED_LIBS=ON \
		-DFMT_TEST=OFF
	+$(MAKE) -C $(BUILD_WORK)/libfmt
	+$(MAKE) -C $(BUILD_WORK)/libfmt install \
		DESTDIR="$(BUILD_STAGE)/libfmt"
	+$(MAKE) -C $(BUILD_WORK)/libfmt install \
		DESTDIR="$(BUILD_BASE)"
	
	touch $(BUILD_WORK)/libfmt/.build_complete
endif

libfmt-package: libfmt-stage
	# libfmt.mk Package Structure
	rm -rf $(BUILD_DIST)/libfmt{7,-dev}
	mkdir -p $(BUILD_DIST)/libfmt{7,-dev}/usr/lib

	# libfmt.mk Prep libfmt7
	cp -a $(BUILD_STAGE)/libfmt/usr/lib/libfmt.{7,$(LIBFMT_VERSION)}.dylib $(BUILD_DIST)/libfmt7/usr/lib

	# libfmt.mk Prep libfmt-dev
	cp -a $(BUILD_STAGE)/libfmt/usr/include $(BUILD_DIST)/libfmt-dev/usr
	cp -a $(BUILD_STAGE)/libfmt/usr/lib/libfmt.dylib $(BUILD_DIST)/libfmt-dev/usr/lib
	cp -a $(BUILD_STAGE)/libfmt/usr/lib/pkgconfig $(BUILD_DIST)/libfmt-dev/usr/lib
	cp -a $(BUILD_STAGE)/libfmt/usr/lib/cmake $(BUILD_DIST)/libfmt-dev/usr/lib

	# libfmt.mk Sign
	$(call SIGN,libfmt7,general.xml)

	# libfmt.mk Make .debs
	$(call PACK,libfmt7,DEB_LIBFMT_V)
	$(call PACK,libfmt-dev,DEB_LIBFMT_V)

	# libfmt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfmt{7,-dev}

.PHONY: libfmt libfmt-package
