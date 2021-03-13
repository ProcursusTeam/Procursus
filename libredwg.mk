ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += libredwg
LIBREDWG_VERSION := 0.12
DEB_LIBREDWG_V   ?= $(LIBREDWG_VERSION)

libredwg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirror.its.dal.ca/gnu/libredwg/libredwg-$(LIBREDWG_VERSION).tar.xz
	$(call EXTRACT_TAR,libredwg-$(LIBREDWG_VERSION).tar.xz,libredwg-$(LIBREDWG_VERSION),libredwg)

ifneq ($(wildcard $(BUILD_WORK)/libredwg/.build_complete),)
libredwg:
	@echo "Using previously built libredwg."
else
libredwg: libredwg-setup
	cd $(BUILD_WORK)/libredwg && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	+$(MAKE) -C $(BUILD_WORK)/libredwg
	+$(MAKE) -C $(BUILD_WORK)/libredwg install \
		DESTDIR=$(BUILD_STAGE)/libredwg
	+$(MAKE) -C $(BUILD_WORK)/libredwg install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libredwg/.build_complete
endif

libredwg-package: libredwg-stage
    # libredwg.mk Package Structure
	rm -rf $(BUILD_DIST)/libredwg{0,-dev,-utils}
	mkdir -p $(BUILD_DIST)/libredwg0/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
			$(BUILD_DIST)/libredwg-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib \
			$(BUILD_DIST)/libredwg-utils/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
    
    # libredwg.mk Prep libredwg
	cp -a $(BUILD_STAGE)/libredwg/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libredwg.0.dylib $(BUILD_DIST)/libredwg0/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	cp -a $(BUILD_STAGE)/libredwg/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,share} $(BUILD_DIST)/libredwg-utils/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/libredwg/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/libredwg-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/libredwg/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/{pkgconfig,libredwg.{a,dylib}} $(BUILD_DIST)/libredwg-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
    
    # libredwg.mk Sign
	$(call SIGN,libredwg-utils,general.xml)
	$(call SIGN,libredwg0,general.xml)
    
    # libredwg.mk Make .debs
	$(call PACK,libredwg0,DEB_LIBREDWG_V)
	$(call PACK,libredwg-dev,DEB_LIBREDWG_V)
	$(call PACK,libredwg-utils,DEB_LIBREDWG_V)
    
    # libredwg.mk Build cleanup
	rm -rf $(BUILD_DIST)/libredwg{0,-dev,-utils}

.PHONY: libredwg libredwg-package
