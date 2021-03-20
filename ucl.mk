ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += ucl
UCL_VERSION := 1.03
DEB_UCL_V   ?= $(UCL_VERSION)

ucl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.oberhumer.com/opensource/ucl/download/ucl-$(UCL_VERSION).tar.gz
	$(call EXTRACT_TAR,ucl-$(UCL_VERSION).tar.gz,ucl-$(UCL_VERSION),ucl)

ifneq ($(wildcard $(BUILD_WORK)/ucl/.build_complete),)
ucl:
	@echo "Using previously built ucl"
else
PATH := $(BUILD_WORK)/ucl/workaround:$(PATH)
ucl: ucl-setup

	# autoconf workaround
	echo "echo $(GNU_HOST_TRIPLE)" > $(BUILD_WORK)/ucl/acconfig/config.sub

	# I can't seem to get dynamic linking working while cross compiling for some reason, so static will do.
	cd $(BUILD_WORK)/ucl && ./configure \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--host=$(GNU_HOST_TRIPLE)
		
	+$(MAKE) -C $(BUILD_WORK)/ucl all
	+$(MAKE) -C $(BUILD_WORK)/ucl install \
		DESTDIR=$(BUILD_STAGE)/ucl
	+$(MAKE) -C $(BUILD_WORK)/ucl install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/ucl/.build_complete
endif

ucl-package: ucl-stage
	# ucl.mk Package Structure
	rm -rf $(BUILD_DIST)/ucl{1,-dev}
	mkdir -p $(BUILD_DIST)/ucl{1,-dev}/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib
	
	# ucl.mk Prep ucl1
	# cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/libucl.a $(BUILD_DIST)/ucl1/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib
	
	# ucl.mk Prep ucl-dev
	cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/libucl.a $(BUILD_DIST)/ucl-dev/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ucl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/ucl-dev/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)
	
	# ucl.mk Sign
	$(call SIGN,ucl1,general.xml)
	
	# ucl.mk Make .debs
	# $(call PACK,ucl1,DEB_UCL_V)
	$(call PACK,ucl-dev,DEB_UCL_V)
	
	# ucl.mk Build cleanup
	rm -rf $(BUILD_DIST)/ucl{1,-dev}

.PHONY: ucl ucl-package
