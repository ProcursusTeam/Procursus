ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += zlib-ng
ZLIB-NG_VERSION  := 2.0.3
DEB_ZLIB-NG_V    ?= $(ZLIB-NG_VERSION)

zlib-ng-setup: setup
	$(call GITHUB_ARCHIVE,zlib-ng,zlib-ng,$(ZLIB-NG_VERSION),$(ZLIB-NG_VERSION))
	$(call EXTRACT_TAR,zlib-ng-$(ZLIB-NG_VERSION).tar.gz,zlib-ng-$(ZLIB-NG_VERSION),zlib-ng)
ifneq ($(wildcard $(BUILD_WORK)/zlib-ng/.build_complete),)
zlib-ng:
	@echo "Using previously built zlib-ng."
else
zlib-ng: zlib-ng-setup
	cd $(BUILD_WORK)/zlib-ng && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/zlib-ng
	+$(MAKE) -C $(BUILD_WORK)/zlib-ng install \
		DESTDIR=$(BUILD_STAGE)/zlib-ng
	+$(MAKE) -C $(BUILD_WORK)/zlib-ng install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/zlib-ng/.build_complete
endif
zlib-ng-package: zlib-ng-stage
	# zlib-ng.mk Package Structure
	rm -rf $(BUILD_DIST)/libz-ng{2,-dev}
	mkdir -p $(BUILD_DIST)/libz-ng{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# zlib-ng.mk Prep libz-ng2
	cp -a $(BUILD_STAGE)/zlib-ng/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libz-ng.2*.dylib $(BUILD_DIST)/libz-ng2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# zlib-ng.mk Prep libz-ng-dev
	cp -a $(BUILD_STAGE)/zlib-ng/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libz-ng.2*.dylib) $(BUILD_DIST)/libz-ng-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/zlib-ng/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libz-ng-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# zlib-ng.mk Sign
	$(call SIGN,libz-ng2,general.xml)

	# zlib-ng.mk Make .debs
	$(call PACK,libz-ng2,DEB_ZLIB-NG_V)
	$(call PACK,libz-ng-dev,DEB_ZLIB-NG_V)

	# zlib-ng.mk Build cleanup
	rm -rf $(BUILD_DIST)/libz-ng{2,-dev}

.PHONY: zlib-ng zlib-ng-package
