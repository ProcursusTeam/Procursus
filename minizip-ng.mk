ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += minizip-ng
MINIZIP-NG_VERSION := 3.0.2
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
		$(DEFAULT_CMAKE_ARGS) \
		-DBUILD_SHARED_LIBS=OFF \
		-DMZ_COMPAT=OFF \
		-DMZ_OPENSSL=ON \
		-DMZ_LIBCOMP=OFF \
		-DMZ_BUILD_TEST=OFF \
		.
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_STAGE)/minizip-ng
	+$(MAKE) -C $(BUILD_WORK)/minizip-ng install \
		DESTDIR=$(BUILD_BASE)

	cd $(BUILD_WORK)/minizip-ng && cmake . \
		$(DEFAULT_CMAKE_ARGS) \
		-DBUILD_SHARED_LIBS=ON \
		-DMZ_COMPAT=OFF \
		-DMZ_LIBCOMP=OFF \
		-DMZ_OPENSSL=ON \
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
