ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += pzb
PZB_VERSION := 36
DEB_PZB_V   ?= $(PZB_VERSION)-1

pzb-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/partialZipBrowser/archive/$(PZB_VERSION).tar.gz
	$(call EXTRACT_TAR,$(PZB_VERSION).tar.gz,partialZipBrowser-$(PZB_VERSION),pzb)

ifneq ($(wildcard $(BUILD_WORK)/pzb/.build_complete),)
pzb:
	@echo "Using previously built pzb."
else
pzb: pzb-setup libfragmentzip
	cd $(BUILD_WORK)/pzb && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/pzb
	+$(MAKE) -C $(BUILD_WORK)/pzb install \
		DESTDIR="$(BUILD_STAGE)/pzb"
	touch $(BUILD_WORK)/pzb/.build_complete
endif

pzb-package: pzb-stage
	# pzb.mk Package Structure
	rm -rf $(BUILD_DIST)/pzb
	mkdir -p $(BUILD_DIST)/pzb
	
	# pzb.mk Prep pzb
	cp -a $(BUILD_STAGE)/pzb $(BUILD_DIST)
	
	# pzb.mk Sign
	$(call SIGN,pzb,general.xml)
	
	# pzb.mk Make .debs
	$(call PACK,pzb,DEB_PZB_V)
	
	# pzb.mk Build cleanup
	rm -rf $(BUILD_DIST)/pzb

.PHONY: pzb pzb-package
