ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += ucl
UCL_VERSION := 1.03
DEB_UCL_V   ?= $(UCL_VERSION)

ucl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.oberhumer.com/opensource/ucl/download/ucl-$(UCL_VERSION).tar.gz
	$(call EXTRACT_TAR,ucl-$(UCL_VERSION).tar.gz,ucl-$(UCL_VERSION),ucl)
	$(call DO_PATCH,ucl,ucl,-p1)

ifneq ($(wildcard $(BUILD_WORK)/ucl/.build_complete),)
ucl:
	@echo "Using previously built ucl"
else
PATH := $(BUILD_WORK)/ucl/workaround:$(PATH)
ucl: ucl-setup
	cd $(BUILD_WORK)/ucl && autoreconf -fi
	cd $(BUILD_WORK)/ucl && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--enable-shared \
		--enable-static
	+$(MAKE) -C $(BUILD_WORK)/ucl all
	+$(MAKE) -C $(BUILD_WORK)/ucl install \
		DESTDIR=$(BUILD_STAGE)/ucl
	+$(MAKE) -C $(BUILD_WORK)/ucl install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/ucl/.build_complete
endif

ucl-package: ucl-stage
	# ucl.mk Package Structure
	rm -rf $(BUILD_DIST)/libucl{1,-dev}
	mkdir -p $(BUILD_DIST)/libucl{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ucl.mk Prep libucl1
	cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libucl.1.dylib $(BUILD_DIST)/libucl1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ucl.mk Prep ucl-dev
	cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libucl.1.dylib) $(BUILD_DIST)/libucl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libucl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ucl.mk Sign
	$(call SIGN,libucl1,general.xml)

	# ucl.mk Make .debs
	$(call PACK,libucl1,DEB_UCL_V)
	$(call PACK,libucl-dev,DEB_UCL_V)

	# ucl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libucl{1,-dev}

.PHONY: ucl ucl-package
