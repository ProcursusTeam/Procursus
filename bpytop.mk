ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += bpytop
BPYTOP_VERSION := 1.0.63
DEB_BPYTOP_V   ?= $(BPYTOP_VERSION)

bpytop-setup: setup
	wget -q -nc -P $(BUILD_SOURCE)  https://github.com/aristocratos/bpytop/archive/refs/tags/v$(BPYTOP_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(BPYTOP_VERSION).tar.gz,bpytop-$(BPYTOP_VERSION),bpytop)

ifneq ($(wildcard $(BUILD_WORK)/bpytop/.build_complete),)
bpytop:
	@echo "Using previously built bpytop."
else
bpytop: bpytop-setup python3
	+$(MAKE) -C $(BUILD_WORK)/bpytop
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		CC="$(CC)" \
		CXX="$(CXX)"
	+$(MAKE) -C $(BUILD_WORK)/bpytop install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/bpytop/
	touch $(BUILD_WORK)/bpytop/.build_complete
endif

bpytop-package: bpytop-stage
    # bpytop.mk Package Structure
	rm -rf $(BUILD_DIST)/bpytop
	mkdir -p $(BUILD_DIST)/bpytop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bpytop.mk Prep bpytop
	cp -a $(BUILD_STAGE)/bpytop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/bpytop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bpytop.mk Sign
	$(call SIGN,bpytop,general.xml)

	# bpytop.mk Make .debs
	$(call PACK,bpytop,DEB_BPYTOP_V)

	# bpytop.mk Build cleanup
	rm -rf $(BUILD_DIST)/bpytop

.PHONY: bpytop bpytop-package
