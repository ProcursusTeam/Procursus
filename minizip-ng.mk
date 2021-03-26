ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += minizip-ng
MINIZIP-NG_VERSION := 3.0.1
DEB_MINIZIP-NG_V   ?= $(MINIZIP-NG_VERSION)

minizip-ng-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/zlib-ng/minizip-ng/archive/refs/tags/$(MINIZIP-NG_VERSION).tar.gz
	$(call EXTRACT_TAR,$(MINIZIP-NG_VERSION).tar.gz,minizip-ng-$(MINIZIP-NG_VERSION),minizip-ng)

ifneq ($(wildcard $(BUILD_WORK)/minizip-ng/.build_complete),)
minizip-ng:
	@echo "Using previously built minizip-ng."
else
minizip-ng: minizip-ng-setup zlib-ng xz zstd openssl
	cd $(BUILD_WORK)/minizip-ng && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)" \
		-DBUILD_SHARED_LIBS=OFF \
		-DMZ_LIBCOMP=OFF \
		.
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_STAGE)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_BASE)

	cd $(BUILD_WORK)/minizip-ng && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)" \
		-DBUILD_SHARED_LIBS=ON \
		-DMZ_LIBCOMP=OFF \
		-DMZ_BUILD_TEST=ON \
		.
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_STAGE)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/minizip-ng/.build_complete
endif
minizip-ng-package: minizip-ng-stage
	# minizip-ng.mk Package Structure
	rm -rf $(BUILD_DIST)/minizip-ng
		rm -rf $(BUILD_DIST)/minizip-ng-dev
		mkdir -p  $(BUILD_DIST)/minizip-ng20/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		mkdir -p  $(BUILD_DIST)/minizip-ng-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		
	# minizip-ng.mk Prep minizip-ng
	cp -a $(BUILD_STAGE)/minizip-ng $(BUILD_DIST)/minizip-ng
	# minizip-ng.mk Sign
	$(call SIGN,minizip-ng,general.xml)
	
	# minizip-ng.mk Make .debs
	$(call PACK,minizip-ng,DEB_MINIZIP-NG_V)
	
	# minizip-ng.mk Build cleanup
	rm -rf $(BUILD_DIST)/minizip-ng

.PHONY: minizip-ng minizip-ng-package
