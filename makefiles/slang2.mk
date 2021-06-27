ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += slang2
SLANG2_VERSION := 2.3.2
DEB_SLANG2_V   ?= $(SLANG2_VERSION)

slang2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.jedsoft.org/releases/slang/slang-$(SLANG2_VERSION).tar.bz2{,.asc}
	$(call PGP_VERIFY,slang-$(SLANG2_VERSION).tar.bz2,asc)
	$(call EXTRACT_TAR,slang-$(SLANG2_VERSION).tar.bz2,slang-$(SLANG2_VERSION),slang2)

ifneq ($(wildcard $(BUILD_WORK)/slang2/.build_complete),)
slang2:
	@echo "Using previously built slang2."
else
slang2: slang2-setup libpng16 pcre libonig
	cd $(BUILD_WORK)/slang2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pcre=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-onig=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-png=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-z=$(TARGET_SYSROOT)/usr
	mkdir -p $(BUILD_WORK)/slang2/src/elfobjs
	+$(MAKE) -C $(BUILD_WORK)/slang2 all
	+$(MAKE) -C $(BUILD_WORK)/slang2 -j1 install \
		DESTDIR=$(BUILD_STAGE)/slang2
	+$(MAKE) -C $(BUILD_WORK)/slang2 -j1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/slang2/.build_complete
endif

slang2-package: slang2-stage
	# slang2.mk Package Structure
	rm -rf $(BUILD_DIST)/slsh $(BUILD_DIST)/libslang2{,-modules,-dev}
	mkdir -p $(BUILD_DIST)/slsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libslang2{,-modules,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# slang2.mk Prep slsh
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)/etc $(BUILD_DIST)/slsh/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/slsh/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# slang2.mk Prep libslang2
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libslang.2*.dylib $(BUILD_DIST)/libslang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# slang2.mk Prep libslang2-modules
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/slang $(BUILD_DIST)/libslang2-modules/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# slang2.mk Prep libslang2-dev
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libslang2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/slang2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libslang.dylib,pkgconfig} $(BUILD_DIST)/libslang2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# slang2.mk Sign
	$(call SIGN,slsh,general.xml)
	$(call SIGN,libslang2,general.xml)
	$(call SIGN,libslang2-modules,general.xml)

	# slang2.mk Make .debs
	$(call PACK,slsh,DEB_SLANG2_V)
	$(call PACK,libslang2,DEB_SLANG2_V)
	$(call PACK,libslang2-modules,DEB_SLANG2_V)
	$(call PACK,libslang2-dev,DEB_SLANG2_V)

	# slang2.mk Build cleanup
	rm -rf $(BUILD_DIST)/slsh $(BUILD_DIST)/libslang2{,-modules,-dev}

.PHONY: slang2 slang2-package
