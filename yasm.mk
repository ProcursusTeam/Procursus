ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += yasm
YASM_VERSION := 1.3.0
DEB_YASM_V   ?= $(YASM_VERSION)

yasm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.tortall.net/projects/yasm/releases/yasm-$(YASM_VERSION).tar.gz
	$(call EXTRACT_TAR,yasm-$(YASM_VERSION).tar.gz,yasm-$(YASM_VERSION),yasm)

ifneq ($(wildcard $(BUILD_WORK)/yasm/.build_complete),)
yasm:
	@echo "Using previously built yasm."
else
yasm: yasm-setup
	cd $(BUILD_WORK)/yasm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-python \
		--disable-debug
	+$(MAKE) -C $(BUILD_WORK)/yasm
	+$(MAKE) -C $(BUILD_WORK)/yasm install \
		DESTDIR=$(BUILD_STAGE)/yasm
	+$(MAKE) -C $(BUILD_WORK)/yasm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/yasm/.build_complete
endif

yasm-package: yasm-stage
	# yasm.mk Package Structure
	rm -rf $(BUILD_DIST)/yasm $(BUILD_DIST)/libyasm-dev
	mkdir -p $(BUILD_DIST)/{yasm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX),libyasm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)}

	# yasm.mk Prep yasm
	cp -a $(BUILD_STAGE)/yasm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/yasm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# yasm.mk Prep libyasm-dev
	cp -a $(BUILD_STAGE)/yasm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} $(BUILD_DIST)/libyasm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# yasm.mk Sign
	$(call SIGN,yasm,general.xml)

	# yasm.mk Make .debs
	$(call PACK,yasm,DEB_YASM_V)
	$(call PACK,libyasm-dev,DEB_YASM_V)

	# yasm.mk Build cleanup
	rm -rf $(BUILD_DIST)/yasm $(BUILD_DIST)/libyasm-dev

.PHONY: yasm yasm-package
