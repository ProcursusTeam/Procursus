ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += i-use-arch-btw
I_USE_ARCH_BTW_VERSION := 0.1.0
I_USE_ARCH_BTW_COMMIT  := 3586240cd12da2152fe96a10b36e86ec38f448c8
LIBIUAB_SOVER          := 0
DEB_I_USE_ARCH_BTW_V   ?= $(I_USE_ARCH_BTW_VERSION)

i-use-arch-btw-setup: setup
	$(call GITHUB_ARCHIVE,overmighty,i-use-arch-btw,$(I_USE_ARCH_BTW_COMMIT),$(I_USE_ARCH_BTW_COMMIT))
	$(call EXTRACT_TAR,i-use-arch-btw-$(I_USE_ARCH_BTW_COMMIT).tar.gz,i-use-arch-btw-$(I_USE_ARCH_BTW_COMMIT),i-use-arch-btw)
	$(call DO_PATCH,i-use-arch-btw,i-use-arch-btw,-p1)
	sed -i 's/@LIBIUAB_SOVER@/$(LIBIUAB_SOVER)/g' $(BUILD_WORK)/i-use-arch-btw/lib/Makefile
	sed -i 's|@MEMO_PREFIX@@MEMO_SUB_PREFIX@|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_WORK)/i-use-arch-btw/lib/Makefile
	mkdir -p $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,lib/pkgconfig}

ifneq ($(wildcard $(BUILD_WORK)/i-use-arch-btw/.build_complete),)
i-use-arch-btw:
	@echo "Using previously built i-use-arch-btw."
else
i-use-arch-btw: i-use-arch-btw-setup
	$(MAKE) -C $(BUILD_WORK)/i-use-arch-btw
	$(MAKE) -C $(BUILD_WORK)/i-use-arch-btw install \
		DESTDIR=$(BUILD_STAGE)/i-use-arch-btw
	mv $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiuab.{,$(LIBIUAB_SOVER).}dylib
	$(LN_S) $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiuab{.$(LIBIUAB_SOVER),}.dylib
	$(call AFTER_BUILD,copy)
endif

i-use-arch-btw-package: i-use-arch-btw-stage
	# i-use-arch-btw.mk Package Structure
	rm -rf $(BUILD_DIST)/{i-use-arch-btw,libiuab{$(LIBIUAB_SOVER),-dev}}
	mkdir -p $(BUILD_DIST)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/libiuab0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libiuab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	
	# i-use-arch-btw.mk Prep i-use-arch-btw
	cp -a $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/i-use-arch-btw $(BUILD_DIST)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# i-use-arch-btw.mk Prep libiuab-dev
	cp -a $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libiuab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libiuab.{a,dylib},pkgconfig} $(BUILD_DIST)/libiuab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# i-use-arch-btw.mk Prep libiuab$(LIBIUAB_SOVER)
	cp -a $(BUILD_STAGE)/i-use-arch-btw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libiuab.$(LIBIUAB_SOVER).dylib $(BUILD_DIST)/libiuab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# i-use-arch-btw.mk Sign
	$(call SIGN,i-use-arch-btw,general.xml)
	$(call SIGN,libiuab$(LIBIUAB_SOVER),general.xml)
	
	# i-use-arch-btw.mk Make .debs
	$(call PACK,i-use-arch-btw,DEB_I_USE_ARCH_BTW_V)
	$(call PACK,libiuab$(LIBIUAB_SOVER),DEB_I_USE_ARCH_BTW_V)
	$(call PACK,libiuab-dev,DEB_I_USE_ARCH_BTW_V)
	
	# i-use-arch-btw.mk Build cleanup
	rm -rf $(BUILD_DIST)/{i-use-arch-btw,libiuab{$(LIBIUAB_SOVER),-dev}}

.PHONY: i-use-arch-btw i-use-arch-btw-package
