ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += zlib-ng
ZLIB-NG_VERSION  := 2.0.2
DEB_ZLIB-NG_V    ?= $(ZLIB-NG_VERSION)

zlib-ng-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/zlib-ng/zlib-ng/archive/refs/tags/$(ZLIB-NG_VERSION).tar.gz
	$(call EXTRACT_TAR,$(ZLIB-NG_VERSION).tar.gz,zlib-ng-$(ZLIB-NG_VERSION),zlib-ng)
ifneq ($(wildcard $(BUILD_WORK)/zlib-ng/.build_complete),)
zlib-ng:
	@echo "Using previously built zlib-ng."
else
zlib-ng: zlib-ng-setup
	cd $(BUILD_WORK)/zlib-ng && cmake . \
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
		-DZLIB_COMPAT=TRUE \
		.
	+$(MAKE) -C $(BUILD_WORK)/zlib-ng
	+$(MAKE) -C $(BUILD_WORK)/zlib-ng install \
		DESTDIR=$(BUILD_STAGE)/zlib-ng
		touch $(BUILD_WORK)/zlib-ng/.build_complete
endif
zlib-ng-package: zlib-ng-stage
	# zlib-ng.mk Package Structure
	rm -rf $(BUILD_DIST)/zlib-ng
		rm -rf $(BUILD_DIST)/zlib-ng-dev
		mkdir -p  $(BUILD_DIST)/zlib-ng20/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		mkdir -p  $(BUILD_DIST)/zlib-ng-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		
	# zlib-ng.mk Prep zlib-ng
	cp -a $(BUILD_STAGE)/zlib-ng $(BUILD_DIST)/zlib-ng
	# zlib-ng.mk Sign
	$(call SIGN,zlib-ng,general.xml)
	
	# zlib-ng.mk Make .debs
	$(call PACK,zlib-ng,DEB_ZLIB-NG_V)
	
	# zlib-ng.mk Build cleanup
	rm -rf $(BUILD_DIST)/zlib-ng

	.PHONY: zlib-ng zlib-ng-package
