ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += librecode
LIBRECODE_VERSION := 3.7.8
DEB_LIBRECODE_V   ?= $(LIBRECODE_VERSION)

librecode-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/rrthomas/recode/releases/download/v$(LIBRECODE_VERSION)/recode-$(LIBRECODE_VERSION).tar.gz
	$(call EXTRACT_TAR,recode-$(LIBRECODE_VERSION).tar.gz,recode-$(LIBRECODE_VERSION),librecode)

ifneq ($(wildcard $(BUILD_WORK)/librecode/.build_complete),)
librecode:
	@echo "Using previously built librecode."
else
librecode: librecode-setup gettext
	cd $(BUILD_WORK)/librecode && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-included-gettext
	+$(MAKE) -C $(BUILD_WORK)/librecode
	+$(MAKE) -C $(BUILD_WORK)/librecode install \
		DESTDIR=$(BUILD_STAGE)/librecode
	+$(MAKE) -C $(BUILD_WORK)/librecode install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/librecode/.build_complete
endif

librecode-package: librecode-stage
	# librecode.mk Package Structure
	rm -rf $(BUILD_DIST)/librecode{3,-dev} $(BUILD_DIST)/recode
	mkdir -p $(BUILD_DIST)/librecode{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# librecode.mk Prep recode
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# librecode.mk Prep librecode3
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librecode.3.dylib $(BUILD_DIST)/librecode3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# librecode.mk Prep librecode-dev
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/librecode-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{librecode.a,librecode.dylib} $(BUILD_DIST)/librecode-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# librecode.mk Sign
	$(call SIGN,recode,general.xml)
	$(call SIGN,librecode3,general.xml)

	# librecode.mk Make .debs
	$(call PACK,recode,DEB_LIBRECODE_V)
	$(call PACK,librecode3,DEB_LIBRECODE_V)
	$(call PACK,librecode-dev,DEB_LIBRECODE_V)

	# librecode.mk Build cleanup
	rm -rf $(BUILD_DIST)/librecode{3,-dev} $(BUILD_DIST)/recode

.PHONY: librecode librecode-package
